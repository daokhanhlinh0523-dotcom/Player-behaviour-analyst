SELECT
    COUNT(*) AS events,
    COUNT(CASE WHEN total_items <= 0 THEN 1 END) AS invalid_total_items,
    COUNT(CASE WHEN unsolved_items < 0 THEN 1 END) AS negative_unsolved_items,
    COUNT(CASE WHEN unsolved_items > total_items THEN 1 END) AS unsolved_gt_total,
    COUNT(CASE WHEN status = 1 AND unsolved_items != 0 THEN 1 END) AS status_1_with_unsolved,
    COUNT(CASE WHEN status != 1 AND unsolved_items = 0 THEN 1 END) AS nonwin_with_zero_unsolved
FROM game_data.level_end;
