SELECT
    'level_start' AS event,
    COUNT(*) AS `rows`,
    COUNT(DISTINCT user_pseudo_id) AS users,
    MIN(event_date) AS min_date,
    MAX(event_date) AS max_date
FROM game_data.level_start

UNION ALL

SELECT
    'level_end',
    COUNT(*),
    COUNT(DISTINCT user_pseudo_id),
    MIN(event_date),
    MAX(event_date)
FROM game_data.level_end;
