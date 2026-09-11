-- Scheduled production per day against a production goal you set by weekday.
-- Answers forum t=8461: "Manually set Daily Production Goal?" - wanting $10k Monday,
--   $12k Tuesday and so on, instead of Open Dental's hourly-goal-per-provider model
--   (which lives in provider.HourlyProdGoalAmt and is not what was asked for).
-- Assumption: "scheduled production" = fees on procedures attached to appointments
--   that are on the books (status 1 Scheduled or 4 ASAP). Edit the goals in the CASE.
-- Read-only. Run in Reports > User Query.

SELECT
    DATE(ap.AptDateTime)                                   AS day,
    DAYNAME(ap.AptDateTime)                                AS weekday,
    ROUND(SUM(pl.ProcFee), 2)                              AS scheduled_production,
    CASE DAYOFWEEK(ap.AptDateTime)                         -- 1=Sun .. 7=Sat
        WHEN 2 THEN 10000    -- Monday      <-- edit your goals
        WHEN 3 THEN 12000    -- Tuesday
        WHEN 4 THEN 12000    -- Wednesday
        WHEN 5 THEN 12000    -- Thursday
        WHEN 6 THEN  8000    -- Friday
        ELSE 0               -- weekend
    END                                                    AS daily_goal,
    ROUND(SUM(pl.ProcFee) - CASE DAYOFWEEK(ap.AptDateTime)
        WHEN 2 THEN 10000 WHEN 3 THEN 12000 WHEN 4 THEN 12000
        WHEN 5 THEN 12000 WHEN 6 THEN 8000 ELSE 0 END, 2)  AS over_under,
    COUNT(DISTINCT ap.AptNum)                              AS appointments
FROM appointment ap
    INNER JOIN procedurelog pl
            ON  pl.AptNum     = ap.AptNum
            AND pl.ProcStatus IN (1, 2)    -- planned or completed work on that appointment
WHERE ap.AptStatus   IN (1, 4)             -- on the books
  AND ap.AptDateTime >= CURDATE()          -- <-- from today forward: edit this
  AND ap.AptDateTime <  CURDATE() + INTERVAL 60 DAY
GROUP BY DATE(ap.AptDateTime), DAYNAME(ap.AptDateTime), DAYOFWEEK(ap.AptDateTime)
ORDER BY day;
