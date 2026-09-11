-- Scheduled production per day against a production goal you set by hand.
-- Answers forum t=8461: "manually set a number for the daily production goal rather than
--   having OD calculate it based on hourly production goal by provider... tomorrow I may
--   set a goal of $10,000 and the following day I may have a goal of $12,000"
--
-- Open Dental's own goal model is hourly and per-provider (provider.HourlyProdGoalAmt),
-- so there is nowhere in the UI to type a number for a specific date. Here the goals live
-- in the query: edit the list below, one row per day, any number you like.
--
-- Assumption: "scheduled production" = fees on procedures attached to appointments that
-- are on the books (AptStatus 1 Scheduled or 4 ASAP). Broken and unscheduled-list
-- appointments are excluded. Procedure fees only - no adjustments or writeoffs.
-- Read-only. Run in Reports > User Query.

SELECT
    g.goal_date,
    DAYNAME(g.goal_date)                                            AS weekday,
    g.daily_goal,
    ROUND(COALESCE(SUM(pl.ProcFee), 0), 2)                          AS scheduled_production,
    ROUND(COALESCE(SUM(pl.ProcFee), 0) - g.daily_goal, 2)           AS over_under,
    COUNT(DISTINCT ap.AptNum)                                       AS appointments
FROM (
    -- ↓↓↓ YOUR GOALS. One row per day. Add or remove rows freely. ↓↓↓
              SELECT DATE('2026-09-14') AS goal_date, 10000 AS daily_goal
    UNION ALL SELECT DATE('2026-09-15'), 12000
    UNION ALL SELECT DATE('2026-09-16'), 12000
    UNION ALL SELECT DATE('2026-09-17'),  9000
    UNION ALL SELECT DATE('2026-09-18'),  8000
    -- ↑↑↑ YOUR GOALS ↑↑↑
) g
    LEFT JOIN appointment ap
           ON  DATE(ap.AptDateTime) = g.goal_date
           AND ap.AptStatus        IN (1, 4)        -- on the books
    LEFT JOIN procedurelog pl
           ON  pl.AptNum     = ap.AptNum
           AND pl.ProcStatus IN (1, 2)              -- planned or completed work
GROUP BY g.goal_date, g.daily_goal
ORDER BY g.goal_date;

-- VARIANT: if your goals repeat by weekday rather than changing per date, replace the
-- derived table above with a generated date range and swap daily_goal for:
--     CASE DAYOFWEEK(d) WHEN 2 THEN 10000 WHEN 3 THEN 12000 WHEN 4 THEN 12000
--                       WHEN 5 THEN 12000 WHEN 6 THEN 8000 ELSE 0 END
