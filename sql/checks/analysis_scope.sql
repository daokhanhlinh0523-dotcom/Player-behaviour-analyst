WITH level_users AS (
    SELECT
        level_index,
        CASE WHEN level_index <= 500 THEN 'Level 1-500' ELSE 'Level >500' END AS scope,
        COUNT(DISTINCT user_pseudo_id) AS starters
    FROM game_data.level_start
    GROUP BY level_index
),
ranked_levels AS (
    SELECT
        scope,
        starters,
        ROW_NUMBER() OVER (PARTITION BY scope ORDER BY starters) AS row_num,
        COUNT(*) OVER (PARTITION BY scope) AS group_size
    FROM level_users
)
SELECT
    scope,
    COUNT(*) AS number_of_levels,
    AVG(CASE
        WHEN row_num IN (FLOOR((group_size + 1) / 2), FLOOR((group_size + 2) / 2))
        THEN starters
    END) AS median_starters,
    MAX(starters) AS max_starters,
    COUNT(CASE WHEN starters >= 500 THEN 1 END) AS levels_with_500_users
FROM ranked_levels
GROUP BY scope
ORDER BY scope;
