-- Every payment plan charge row, including ones dated in the future.
-- Answers forum t=8699: charges the Open Dental GUI displays but that a payplancharge
--   query and GET /payplancharges both miss.
--
-- WHY YOUR QUERY MISSES THEM: on a DYNAMIC payment plan, Open Dental does not store
-- future "expected" charges as payplancharge rows. It calculates them for display.
-- So they are not missing from your query - they do not exist as rows yet. That is
-- also why the API's getExpected returns nothing: it is not implemented (staff
-- confirmed on the thread, no ETA). Anything dated in the future that DOES appear
-- below is a real, materialised row.
--
-- To reconcile ortho remaining-months against remaining-charges you have to project
-- the schedule yourself from payplan.NumberOfPayments, PayAmt, ChargeFrequency and
-- DatePayPlanStart, and subtract the charges that already exist. The last two columns
-- give you that.
-- Read-only. Run in Reports > User Query.

SELECT
    pp.PayPlanNum,
    pat.PatNum,
    pat.LName,
    pat.FName,
    CASE pp.IsDynamic WHEN 1 THEN 'Dynamic' ELSE 'Fixed' END   AS plan_type,
    pp.DatePayPlanStart,
    pp.NumberOfPayments,
    ROUND(pp.PayAmt, 2)                                        AS scheduled_payment,
    ppc.PayPlanChargeNum,
    ppc.ChargeDate,
    CASE WHEN ppc.ChargeDate > CURDATE() THEN 'FUTURE' ELSE 'DUE/PAST' END AS timing,
    ROUND(ppc.Principal, 2)                                    AS principal,
    ROUND(ppc.Interest, 2)                                     AS interest,
    COUNT(*)      OVER (PARTITION BY pp.PayPlanNum)            AS charge_rows_that_exist,
    pp.NumberOfPayments - COUNT(*) OVER (PARTITION BY pp.PayPlanNum) AS charge_rows_not_yet_created
FROM payplan pp
    INNER JOIN patient       pat ON pat.PatNum    = pp.PatNum
    LEFT  JOIN payplancharge ppc ON ppc.PayPlanNum = pp.PayPlanNum
WHERE pp.IsClosed = 0
ORDER BY pp.PayPlanNum, ppc.ChargeDate;
