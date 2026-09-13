-- Every patient currently on a discount plan, with the plan and the fee schedule behind it.
-- Answers forum t=7744, "Custom Query for Discount Plan".
-- Two things make this harder than it looks. Open Dental moved discount plans from a single
--   field on the patient (patient.DiscountPlanNum) to their own subscription table
--   (discountplansub) with effective and termination dates. Both still exist. A query that
--   reads only one of them will miss patients on any practice that has been running long
--   enough to span the change.
-- This reads the subscription table, which is authoritative on 21.1 and later, and reports
--   the legacy field alongside so you can see any patient where the two disagree.
-- Assumption: a subscription with DateTerm of 0000-00-00 or NULL has not been terminated.
--   Open Dental stores "no date" as the zero date rather than NULL in most date columns, and
--   0000-00-00 compares as smaller than every real date, so a plain `DateTerm >= CURDATE()`
--   silently drops every patient whose plan has no end date. YEAR(x) < 1880 is the test used
--   throughout this file for "this date was never set".
-- Read-only. Run in Reports > User Query.

SELECT
    pat.PatNum,
    CONCAT(pat.LName, ', ', pat.FName)              AS patient,
    pat.WirelessPhone,
    dp.Description                                  AS discount_plan,
    COALESCE(NULLIF(fs.Description, ''), '')        AS fee_schedule,
    sub.DateEffective                               AS effective_from,
    CASE WHEN sub.DateTerm IS NULL OR YEAR(sub.DateTerm) < 1880
         THEN '' ELSE CAST(sub.DateTerm AS CHAR) END AS terminates,
    dp.AnnualMax                                    AS annual_max,
    CASE WHEN pat.DiscountPlanNum = sub.DiscountPlanNum THEN ''
         ELSE 'legacy field disagrees' END          AS check_this,
    CASE pat.PatStatus WHEN 0 THEN 'Patient' WHEN 1 THEN 'NonPatient' WHEN 2 THEN 'Inactive'
         WHEN 3 THEN 'Archived' WHEN 4 THEN 'Deceased' WHEN 5 THEN 'Prospective'
         ELSE CONCAT('Status ', pat.PatStatus) END  AS patient_status
FROM discountplansub sub
    INNER JOIN discountplan dp  ON dp.DiscountPlanNum = sub.DiscountPlanNum
    INNER JOIN patient      pat ON pat.PatNum         = sub.PatNum
    LEFT  JOIN feesched     fs  ON fs.FeeSchedNum     = dp.FeeSchedNum
WHERE (sub.DateTerm IS NULL OR YEAR(sub.DateTerm) < 1880 OR sub.DateTerm >= CURDATE())
  AND (sub.DateEffective IS NULL OR YEAR(sub.DateEffective) < 1880 OR sub.DateEffective <= CURDATE())
ORDER BY dp.Description, pat.LName, pat.FName;

-- If you are on a version before 21.1, or the result comes back empty and you know you have
-- discount plan patients, the plan is on the patient record instead. Run this:
--
-- SELECT pat.PatNum, CONCAT(pat.LName, ', ', pat.FName) AS patient, dp.Description AS discount_plan
-- FROM patient pat
--     INNER JOIN discountplan dp ON dp.DiscountPlanNum = pat.DiscountPlanNum
-- WHERE pat.DiscountPlanNum > 0 AND pat.PatStatus = 0
-- ORDER BY dp.Description, pat.LName;
