-- Payment plans by patient with principal, amount charged to date, paid, and due as of a date.
-- Answers forum t=8211: "all payment plans by patient # with type, category, principal,
--   balance, and due now as of 12/31/2023"
-- Assumption: "due as of" = charges dated on or before the as-of date, minus payments
--   allocated to the plan on or before that date. Edit the as-of date in both places.
-- Read-only. Run in Reports > User Query.

SELECT
    pp.PayPlanNum,
    pat.PatNum,
    pat.LName,
    pat.FName,
    pp.PayPlanDate,
    pp.PlanCategory,
    CASE pp.IsDynamic WHEN 1 THEN 'Dynamic' ELSE 'Fixed' END        AS plan_type,
    ROUND(pp.CompletedAmt, 2)                                       AS principal,
    ROUND(COALESCE(chg.charged, 0), 2)                              AS charged_to_date,
    ROUND(COALESCE(pay.paid, 0), 2)                                 AS paid_to_date,
    ROUND(COALESCE(chg.charged, 0) - COALESCE(pay.paid, 0), 2)      AS due_now
FROM payplan pp
    INNER JOIN patient pat ON pat.PatNum = pp.PatNum
    LEFT JOIN (
        SELECT PayPlanNum, SUM(Principal + Interest) AS charged
        FROM payplancharge
        WHERE ChargeDate <= '2026-12-31'        -- <-- as-of date: edit this
        GROUP BY PayPlanNum
    ) chg ON chg.PayPlanNum = pp.PayPlanNum
    LEFT JOIN (
        SELECT PayPlanNum, SUM(SplitAmt) AS paid
        FROM paysplit
        WHERE PayPlanNum > 0
          AND DatePay <= '2026-12-31'           -- <-- same as-of date: edit this
        GROUP BY PayPlanNum
    ) pay ON pay.PayPlanNum = pp.PayPlanNum
WHERE pp.IsClosed = 0
ORDER BY due_now DESC;
