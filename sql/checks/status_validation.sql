SELECT
    status,
    COUNT(*) AS events,
    ROUND(COUNT(CASE WHEN unsolved_items = 0 THEN 1 END) / COUNT(*), 4) AS zero_unsolved_rate,
    ROUND(
        COUNT(CASE WHEN total_items > 0 AND unsolved_items BETWEEN 0 AND total_items THEN 1 END)
        / COUNT(*), 4
    ) AS valid_item_rate,
    ROUND(AVG(unsolved_items), 2) AS avg_unsolved_items,
    ROUND(AVG(total_items), 2) AS avg_total_items
FROM game_data.level_end
GROUP BY status
ORDER BY status;
