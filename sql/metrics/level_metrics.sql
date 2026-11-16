WITH unique_start_events AS (
    SELECT DISTINCT
        event_timestamp, user_pseudo_id, level_index, level_id, attempt
    FROM game_data.level_start
    WHERE level_index BETWEEN 1 AND 500
),
unique_end_events AS (
    SELECT DISTINCT
        event_timestamp, user_pseudo_id, level_index, status, playtime, attempt, unsolved_items
    FROM game_data.level_end
    WHERE level_index BETWEEN 1 AND 500
),
level_starts AS (
    SELECT
        level_index,
        COUNT(DISTINCT level_id) AS level_variants,
        COUNT(*) AS start_events,
        COUNT(DISTINCT user_pseudo_id) AS start_users
    FROM unique_start_events
    GROUP BY level_index
),
level_ends AS (
    SELECT
        level_index,
        COUNT(*) AS end_events,
        COUNT(DISTINCT user_pseudo_id) AS end_users,
        COUNT(CASE WHEN status = 1 THEN 1 END) AS win_events,
        COUNT(CASE WHEN status != 1 THEN 1 END) AS non_win_events,
        COUNT(CASE WHEN attempt = 1 AND status = 1 THEN 1 END) AS first_attempt_wins,
        COUNT(CASE WHEN attempt = 1 THEN 1 END) AS first_attempt_ends,
        ROUND(AVG(CASE WHEN status = 1 THEN attempt END), 2) AS avg_attempt_at_win
    FROM unique_end_events
    GROUP BY level_index
),
ranked_win_times AS (
    SELECT
        level_index,
        playtime,
        ROW_NUMBER() OVER (PARTITION BY level_index ORDER BY playtime) AS row_num,
        COUNT(*) OVER (PARTITION BY level_index) AS group_size
    FROM unique_end_events
    WHERE status = 1 AND playtime IS NOT NULL
),
win_times AS (
    SELECT level_index, AVG(playtime) AS median_win_time
    FROM ranked_win_times
    WHERE row_num IN (FLOOR((group_size + 1) / 2), FLOOR((group_size + 2) / 2))
    GROUP BY level_index
),
first_starts AS (
    SELECT
        user_pseudo_id,
        level_index,
        MIN(event_timestamp) AS first_start_ts
    FROM game_data.level_start
    WHERE level_index BETWEEN 1 AND 501
    GROUP BY user_pseudo_id, level_index
),
level_transitions AS (
    SELECT
        current_level.level_index,
        COUNT(*) AS eligible_users,
        COUNT(CASE
            WHEN next_level.first_start_ts > current_level.first_start_ts
                AND next_level.first_start_ts <= current_level.first_start_ts + 86400000000
            THEN 1
        END) AS transitioned_24h
    FROM first_starts AS current_level
    LEFT JOIN first_starts AS next_level
        ON current_level.user_pseudo_id = next_level.user_pseudo_id
        AND next_level.level_index = current_level.level_index + 1
    WHERE current_level.level_index BETWEEN 1 AND 500
        AND current_level.first_start_ts <= (
            SELECT MAX(event_timestamp) - 86400000000 FROM game_data.level_start
        )
    GROUP BY current_level.level_index
)
SELECT
    level_starts.level_index,
    level_starts.level_variants,
    level_starts.start_events,
    level_starts.start_users,
    level_ends.end_events,
    level_ends.end_users,
    level_ends.win_events,
    level_ends.non_win_events,
    level_ends.first_attempt_wins,
    level_ends.first_attempt_ends,
    win_times.median_win_time,
    level_ends.avg_attempt_at_win,
    level_transitions.eligible_users,
    level_transitions.transitioned_24h
FROM level_starts
LEFT JOIN level_ends USING (level_index)
LEFT JOIN win_times USING (level_index)
LEFT JOIN level_transitions USING (level_index)
ORDER BY level_index;
