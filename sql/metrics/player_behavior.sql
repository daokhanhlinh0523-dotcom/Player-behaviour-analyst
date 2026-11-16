WITH unique_end_events AS (
    SELECT DISTINCT
        event_timestamp, user_pseudo_id, level_index, status, attempt, move,
        unsolved_items, total_items, revive, booster_0, booster_1, booster_2, booster_3
    FROM game_data.level_end
    WHERE level_index BETWEEN 1 AND 500
),
behavior AS (
    SELECT
        level_index,
        ROUND(
            COUNT(CASE WHEN attempt = 1 AND status = 1 THEN 1 END)
            / NULLIF(COUNT(CASE WHEN attempt = 1 THEN 1 END), 0), 4
        ) AS first_attempt_win_rate,
        ROUND(COUNT(CASE WHEN attempt >= 5 THEN 1 END) / COUNT(*), 4) AS attempt_5plus_share,
        ROUND(AVG(CASE
            WHEN status != 1 AND total_items > 0
            THEN unsolved_items / NULLIF(total_items, 0)
        END), 4) AS avg_unsolved_share,
        ROUND(COUNT(CASE WHEN revive > 0 THEN 1 END) / COUNT(*), 4) AS revive_use_rate,
        ROUND(
            COUNT(CASE WHEN booster_0 > 0 OR booster_1 > 0 OR booster_2 > 0 OR booster_3 > 0 THEN 1 END)
            / COUNT(*), 4
        ) AS booster_use_rate
    FROM unique_end_events
    GROUP BY level_index
),
ranked_moves AS (
    SELECT
        level_index,
        move,
        ROW_NUMBER() OVER (PARTITION BY level_index ORDER BY move) AS row_num,
        COUNT(*) OVER (PARTITION BY level_index) AS group_size
    FROM unique_end_events
    WHERE status != 1 AND move IS NOT NULL
),
unsuccessful_moves AS (
    SELECT level_index, AVG(move) AS median_unsuccess_moves
    FROM ranked_moves
    WHERE row_num IN (FLOOR((group_size + 1) / 2), FLOOR((group_size + 2) / 2))
    GROUP BY level_index
)
SELECT
    behavior.level_index,
    behavior.first_attempt_win_rate,
    behavior.attempt_5plus_share,
    unsuccessful_moves.median_unsuccess_moves,
    behavior.avg_unsolved_share,
    behavior.revive_use_rate,
    behavior.booster_use_rate
FROM behavior
LEFT JOIN unsuccessful_moves USING (level_index)
ORDER BY level_index;
