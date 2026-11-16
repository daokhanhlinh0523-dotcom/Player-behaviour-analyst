WITH unique_cohort_events AS (
    SELECT DISTINCT
        event_timestamp,
        user_pseudo_id,
        level_index,
        status,
        DATE(TIMESTAMPADD(
            MICROSECOND,
            user_first_touch_timestamp + time_zone_offset_seconds * 1000000,
            CAST('1970-01-01 00:00:00' AS DATETIME)
        )) AS cohort_date
    FROM game_data.level_end
    WHERE level_index IN (107, 109, 144)
)
SELECT
    level_index,
    CASE
        WHEN cohort_date <= '2026-08-03' THEN '31/07-03/08'
        WHEN cohort_date <= '2026-08-07' THEN '04/08-07/08'
        ELSE '08/08-10/08'
    END AS cohort,
    COUNT(DISTINCT user_pseudo_id) AS users,
    COUNT(*) AS attempts,
    ROUND(COUNT(CASE WHEN status = 1 THEN 1 END) / COUNT(*), 4) AS attempt_win_rate
FROM unique_cohort_events
WHERE cohort_date BETWEEN '2026-07-31' AND '2026-08-10'
GROUP BY level_index, cohort
ORDER BY level_index, cohort;
