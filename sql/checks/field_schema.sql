SELECT
    COLUMN_NAME AS name,
    COLUMN_TYPE AS type,
    COLUMN_COMMENT AS comment
FROM information_schema.columns
WHERE TABLE_SCHEMA = 'game_data'
    AND TABLE_NAME = 'level_end'
    AND COLUMN_NAME IN ('status', 'unsolved_items', 'total_items')
ORDER BY COLUMN_NAME;
