WITH data_end AS (
    SELECT MAX(event_date) AS max_date, MAX(event_timestamp) AS max_ts
    FROM game_data.level_start
),
unique_level_109_ends AS (
    SELECT DISTINCT
        event_timestamp, user_pseudo_id, status, attempt,
        revive, booster_0, booster_1, booster_2, booster_3
    FROM game_data.level_end
    WHERE level_index = 109
),
first_level_109 AS (
    SELECT
        user_pseudo_id,
        MIN(event_timestamp) AS first_ts,
        MIN(event_date) AS first_date
    FROM game_data.level_start
    WHERE level_index = 109
    GROUP BY user_pseudo_id
),
first_attempt_results AS (
    SELECT
        user_pseudo_id,
        MAX(CASE WHEN attempt = 1
            AND (booster_0 > 0 OR booster_1 > 0 OR booster_2 > 0 OR booster_3 > 0)
            THEN 1 ELSE 0 END) AS first_attempt_booster,
        MAX(CASE WHEN attempt = 1 AND revive > 0 THEN 1 ELSE 0 END) AS first_attempt_revive,
        MAX(CASE WHEN attempt = 1 AND status = 1 THEN 1 ELSE 0 END) AS first_attempt_win
    FROM unique_level_109_ends
    GROUP BY user_pseudo_id
),
active_days AS (
    SELECT DISTINCT user_pseudo_id, event_date AS active_date
    FROM game_data.level_start
),
first_level_110 AS (
    SELECT user_pseudo_id, MIN(event_timestamp) AS next_ts
    FROM game_data.level_start
    WHERE level_index = 110
    GROUP BY user_pseudo_id
),
purchases_in_24h AS (
    SELECT
        first_play.user_pseudo_id,
        COUNT(purchases.event_timestamp) AS iap_events_24h,
        SUM(COALESCE(purchases.event_value_in_usd, 0)) AS iap_revenue_24h
    FROM first_level_109 AS first_play
    LEFT JOIN game_data.in_app_purchase AS purchases
        ON first_play.user_pseudo_id = purchases.user_pseudo_id
        AND purchases.event_timestamp >= first_play.first_ts
        AND purchases.event_timestamp <= first_play.first_ts + 86400000000
    GROUP BY first_play.user_pseudo_id
)
SELECT
    first_play.user_pseudo_id,
    attempt_result.first_attempt_booster,
    attempt_result.first_attempt_revive,
    attempt_result.first_attempt_win,
    CASE WHEN first_play.first_date < data_end.max_date THEN 1 ELSE 0 END AS d1_eligible,
    CASE WHEN activity.active_date IS NOT NULL THEN 1 ELSE 0 END AS next_day_return,
    CASE WHEN first_play.first_ts <= data_end.max_ts - 86400000000
        THEN 1 ELSE 0 END AS transition_eligible,
    CASE WHEN next_play.next_ts > first_play.first_ts
        AND next_play.next_ts <= first_play.first_ts + 86400000000
        THEN 1 ELSE 0 END AS transition_24h,
    purchases.iap_events_24h,
    purchases.iap_revenue_24h
FROM first_level_109 AS first_play
CROSS JOIN data_end
INNER JOIN first_attempt_results AS attempt_result
    ON first_play.user_pseudo_id = attempt_result.user_pseudo_id
LEFT JOIN active_days AS activity
    ON first_play.user_pseudo_id = activity.user_pseudo_id
    AND activity.active_date = DATE_ADD(first_play.first_date, INTERVAL 1 DAY)
LEFT JOIN first_level_110 AS next_play
    ON first_play.user_pseudo_id = next_play.user_pseudo_id
LEFT JOIN purchases_in_24h AS purchases
    ON first_play.user_pseudo_id = purchases.user_pseudo_id;
