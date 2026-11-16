WITH level_events AS (
    SELECT
        user_pseudo_id,
        level_index,
        event_timestamp,
        event_date,
        platform
    FROM game_data.level_start
    WHERE level_index BETWEEN 1 AND 500
        AND user_pseudo_id IS NOT NULL
        AND user_pseudo_id != ''
        AND event_date IS NOT NULL
),
ranked_starts AS (
    SELECT
        user_pseudo_id,
        level_index,
        platform,
        MIN(event_date) OVER (PARTITION BY user_pseudo_id, level_index) AS first_level_date,
        ROW_NUMBER() OVER (
            PARTITION BY user_pseudo_id, level_index
            ORDER BY platform IS NULL, event_timestamp IS NULL, event_timestamp, platform
        ) AS row_num
    FROM level_events
),
first_level AS (
    SELECT user_pseudo_id, level_index, first_level_date, platform
    FROM ranked_starts
    WHERE row_num = 1
),
active_days AS (
    SELECT DISTINCT user_pseudo_id, event_date AS active_date
    FROM game_data.level_start
    WHERE user_pseudo_id IS NOT NULL
        AND user_pseudo_id != ''
        AND event_date IS NOT NULL
)
SELECT
    first_play.level_index,
    first_play.platform,
    COUNT(*) AS retention_eligible_users,
    COUNT(activity.active_date) AS next_day_users,
    ROUND(COUNT(activity.active_date) / COUNT(*), 4) AS next_day_return_rate
FROM first_level AS first_play
LEFT JOIN active_days AS activity
    ON first_play.user_pseudo_id = activity.user_pseudo_id
    AND activity.active_date = DATE_ADD(first_play.first_level_date, INTERVAL 1 DAY)
WHERE first_play.first_level_date < (SELECT MAX(event_date) FROM game_data.level_start)
GROUP BY first_play.level_index, first_play.platform
ORDER BY first_play.level_index, first_play.platform;
