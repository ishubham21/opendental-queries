-- How much of each month's production has actually been collected since, and how long it
-- took. Answers forum t=7780, "Collections Waterfall Report".
-- Production and collections are usually reported side by side for the same month, which
--   compares work done in March against money received in March, most of which is for
--   work done earlier. This lines the money up against the month the work was done.
-- Assumption: a payment split carries ProcDate, the date of the procedure it pays for, as
--   well as DatePay. That is what makes the match possible. Splits with no ProcDate are
--   unattached credits and are excluded rather than guessed at.
-- ProcStatus 2 = Complete. UnearnedType 0 = earned income.
-- Read-only. Run in Reports > User Query. Edit the date window.

SELECT
    DATE_FORMAT(pl.ProcDate, '%Y-%m')                       AS production_month,
    ROUND(SUM(pl.ProcFee), 2)                               AS production,
    ROUND((SELECT SUM(ps.SplitAmt) FROM paysplit ps
            WHERE ps.UnearnedType = 0
              AND ps.ProcDate <> '0001-01-01'
              AND DATE_FORMAT(ps.ProcDate, '%Y-%m') = DATE_FORMAT(pl.ProcDate, '%Y-%m')), 2)
                                                            AS collected_to_date,
    ROUND(100 * (SELECT SUM(ps.SplitAmt) FROM paysplit ps
                  WHERE ps.UnearnedType = 0
                    AND ps.ProcDate <> '0001-01-01'
                    AND DATE_FORMAT(ps.ProcDate, '%Y-%m') = DATE_FORMAT(pl.ProcDate, '%Y-%m'))
             / NULLIF(SUM(pl.ProcFee), 0), 1)               AS collected_pct,
    ROUND((SELECT AVG(DATEDIFF(ps.DatePay, ps.ProcDate)) FROM paysplit ps
            WHERE ps.UnearnedType = 0
              AND ps.ProcDate <> '0001-01-01'
              AND ps.DatePay >= ps.ProcDate
              AND DATE_FORMAT(ps.ProcDate, '%Y-%m') = DATE_FORMAT(pl.ProcDate, '%Y-%m')), 0)
                                                            AS avg_days_to_collect
FROM procedurelog pl
WHERE pl.ProcStatus = 2
  AND pl.ProcDate BETWEEN '2026-01-01' AND '2026-09-30'
GROUP BY production_month
ORDER BY production_month;
