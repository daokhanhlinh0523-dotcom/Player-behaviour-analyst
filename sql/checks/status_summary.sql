WITH ranked_events AS (
    SELECT
        status,
        user_pseudo_id,
        playtime,
        move,
        unsolved_items,
        total_items,
        ROW_NUMBER() OVER (PARTITION BY status ORDER BY playtime IS NULL, playtime) AS playtime_rank,
        COUNT(playtime) OVER (PARTITION BY status) AS playtime_count,
        ROW_NUMBER() OVER (PARTITION BY status ORDER BY move IS NULL, move) AS move_rank,
        COUNT(move) OVER (PARTITION BY status) AS move_count,
        ROW_NUMBER() OVER (PARTITION BY status ORDER BY unsolved_items IS NULL, unsolved_items) AS unsolved_items_rank,
        COUNT(unsolved_items) OVER (PARTITION BY status) AS unsolved_items_count
    FROM game_data.level_end
)
SELECT
    status,
    COUNT(*) AS events,
    COUNT(DISTINCT user_pseudo_id) AS users,
    ROUND(COUNT(*) / (SELECT COUNT(*) FROM game_data.level_end), 4) AS event_share,
    AVG(CASE
        WHEN playtime_rank IN (
            FLOOR((playtime_count + 1) / 2), FLOOR((playtime_count + 2) / 2)
        ) THEN playtime
    END) AS median_playtime,
    AVG(CASE
        WHEN move_rank IN (
            FLOOR((move_count + 1) / 2), FLOOR((move_count + 2) / 2)
        ) THEN move
    END) AS median_move,
    AVG(CASE
        WHEN unsolved_items_rank IN (
            FLOOR((unsolved_items_count + 1) / 2), FLOOR((unsolved_items_count + 2) / 2)
        ) THEN unsolved_items
    END) AS median_unsolved
FROM ranked_events
GROUP BY status
ORDER BY status;
