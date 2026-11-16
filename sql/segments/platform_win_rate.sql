WITH unique_platform_events AS (
    SELECT DISTINCT event_timestamp, user_pseudo_id, level_index, status, platform
    FROM game_data.level_end
    WHERE level_index IN (107, 109, 144)
)
SELECT
    level_index,
    platform,
    COUNT(DISTINCT user_pseudo_id) AS users,
    COUNT(*) AS attempts,
    ROUND(COUNT(CASE WHEN status = 1 THEN 1 END) / COUNT(*), 4) AS attempt_win_rate
FROM unique_platform_events
GROUP BY level_index, platform
ORDER BY level_index, platform;
