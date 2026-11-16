WITH level_variants AS (
    SELECT
        level_index,
        COUNT(DISTINCT level_id) AS ids_at_index
    FROM game_data.level_start
    GROUP BY level_index
)
SELECT MIN(level_index) AS first_index_with_multiple_ids
FROM level_variants
WHERE ids_at_index > 1;
