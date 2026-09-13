-- Discount plan patients with production, plan writeoffs, other adjustments and payments,
--   over a date range. One row per patient, plus a total row.
-- Answers forum t=7744, which Open Dental's own library does not. The library has #1575,
--   "Patients with discount plans", and it is a membership list. The person who opened that
--   thread said plainly what was missing, twice, and never got it: "there's nothing that puts
--   all the information together (Patient + Production + Adjustment + Patient Income)". They
--   were trying to work out whether their in-house plan was actually profitable.
--
-- THE TRAP, and it is the whole reason this query is shaped the way it is.
--   The obvious version joins procedurelog, adjustment and paysplit to patient in one FROM
--   clause and sums each column. That multiplies. A patient with 4 procedures, 2 adjustments
--   and 3 payments produces 24 rows, and every SUM is inflated by the count of the other two
--   tables. Production comes back roughly six times too high and the number looks plausible
--   enough to act on.
--   Each total below is therefore computed in its own subquery, grouped by PatNum, and only
--   then joined. That is also why COALESCE wraps every one of them: a patient with production
--   and no payments must read 0.00, not NULL.
--
-- Assumptions, all of which you should check against how your office records things:
--   - Production is completed procedures only, ProcStatus = 2, by ProcDate, summed as
--     ProcFee. It does not multiply by UnitQty or BaseUnits. Those matter for Canadian time
--     units and a few anesthesia codes, and queries 06 and 25 in this repository sum ProcFee
--     the same way, so the three agree with each other. If your office bills in time units,
--     all three need the same change, not just this one.
--   - procedurelog.DiscountPlanAmt is the per-procedure discount the plan gave. Open Dental
--     records it on the procedure itself, so it does not need to be found among adjustments.
--   - Adjustments are counted by AdjDate and are signed as stored, so a writeoff is negative.
--   - Payments are patient payments (paysplit) by DatePay. Insurance payments are not here;
--     a discount plan patient normally has no insurance, which is the point of the plan.
--   - The plan membership fee is NOT separated out. Practices record it as a payment, an
--     adjustment or a procedure code, and there is no field that marks it, so I cannot tell
--     which from the schema. If you record it as a code, add its ProcCode to the note below.
-- Read-only. Run in Reports > User Query. Edit the two dates.

SET @FromDate = '2026-01-01';
SET @ToDate   = '2026-12-31';

SELECT
    pat.PatNum,
    CONCAT(pat.LName, ', ', pat.FName)            AS patient,
    dp.Description                                AS discount_plan,
    COALESCE(prod.gross_production, 0)            AS gross_production,
    COALESCE(prod.plan_discount, 0)               AS plan_discount,
    COALESCE(prod.gross_production, 0) - COALESCE(prod.plan_discount, 0) AS net_production,
    COALESCE(adj.adjustments, 0)                  AS other_adjustments,
    COALESCE(pay.payments, 0)                     AS patient_payments,
    COALESCE(pay.payments, 0)
      - (COALESCE(prod.gross_production, 0) - COALESCE(prod.plan_discount, 0)
         + COALESCE(adj.adjustments, 0))          AS collected_minus_net,
    COALESCE(prod.procedures, 0)                  AS procedure_count
FROM discountplansub sub
    INNER JOIN discountplan dp  ON dp.DiscountPlanNum = sub.DiscountPlanNum
    INNER JOIN patient      pat ON pat.PatNum         = sub.PatNum
    LEFT JOIN (
        SELECT pl.PatNum,
               ROUND(SUM(pl.ProcFee), 2)          AS gross_production,
               ROUND(SUM(pl.DiscountPlanAmt), 2)  AS plan_discount,
               COUNT(*)                           AS procedures
        FROM procedurelog pl
        WHERE pl.ProcStatus = 2 AND pl.ProcDate BETWEEN @FromDate AND @ToDate
        GROUP BY pl.PatNum
    ) prod ON prod.PatNum = pat.PatNum
    LEFT JOIN (
        SELECT a.PatNum, SUM(a.AdjAmt) AS adjustments
        FROM adjustment a
        WHERE a.AdjDate BETWEEN @FromDate AND @ToDate
        GROUP BY a.PatNum
    ) adj ON adj.PatNum = pat.PatNum
    LEFT JOIN (
        SELECT ps.PatNum, SUM(ps.SplitAmt) AS payments
        FROM paysplit ps
        WHERE ps.DatePay BETWEEN @FromDate AND @ToDate
        GROUP BY ps.PatNum
    ) pay ON pay.PatNum = pat.PatNum
WHERE (sub.DateTerm IS NULL OR YEAR(sub.DateTerm) < 1880 OR sub.DateTerm >= @FromDate)
  AND (sub.DateEffective IS NULL OR YEAR(sub.DateEffective) < 1880 OR sub.DateEffective <= @ToDate)
ORDER BY COALESCE(prod.gross_production, 0) DESC;

-- The number the thread was actually after is the bottom line across the plan, so run this
-- second query for the totals. It repeats the subqueries deliberately rather than using a
-- WITH clause, because Open Dental still runs on MySQL 5.7 in plenty of offices and common
-- table expressions do not exist there.
--
-- SELECT COUNT(DISTINCT pat.PatNum)                    AS patients_on_plan,
--        SUM(COALESCE(prod.gross_production, 0))       AS gross_production,
--        SUM(COALESCE(prod.plan_discount, 0))          AS plan_discount_given,
--        SUM(COALESCE(adj.adjustments, 0))             AS other_adjustments,
--        SUM(COALESCE(pay.payments, 0))                AS patient_payments
-- FROM ... (the same FROM and WHERE as above);
