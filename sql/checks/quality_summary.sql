WITH start_keys AS (
    SELECT DISTINCT event_timestamp, user_pseudo_id, level_index, attempt
    FROM game_data.level_start
),
end_keys AS (
    SELECT DISTINCT event_timestamp, user_pseudo_id, level_index, attempt, status
    FROM game_data.level_end
)
SELECT
    'level_start' AS event,
    COUNT(*) AS `rows`,
    COUNT(*) - (SELECT COUNT(*) FROM start_keys) AS repeated_event_keys,
    COUNT(CASE WHEN user_pseudo_id IS NULL OR user_pseudo_id = '' THEN 1 END) AS bad_user,
    COUNT(CASE WHEN level_index IS NULL THEN 1 END) AS null_level,
    COUNT(CASE WHEN event_timestamp IS NULL THEN 1 END) AS null_timestamp
FROM game_data.level_start

UNION ALL

SELECT
    'level_end',
    COUNT(*),
    COUNT(*) - (SELECT COUNT(*) FROM end_keys),
    COUNT(CASE WHEN user_pseudo_id IS NULL OR user_pseudo_id = '' THEN 1 END),
    COUNT(CASE WHEN level_index IS NULL THEN 1 END),
    COUNT(CASE WHEN event_timestamp IS NULL THEN 1 END)
FROM game_data.level_end;
