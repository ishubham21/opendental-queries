-- Patients with insurance money left on the table before the plan year closes.
-- This is the October-to-December call list, and the single most valuable report a
-- practice can run in Q4.
--
-- READ THIS BEFORE YOU TRUST THE 'remaining' COLUMN.
-- Open Dental stores the annual maximum as a row in `benefit`, and which numeric
-- `BenefitType` means "Limitations" is not something I will guess on your behalf. So this
-- query does NOT hard-code it. It takes the largest monetary benefit attached to the plan
-- with no coverage category (CovCatNum = 0), which on every plan I have seen is the annual
-- maximum, and it prints `annual_max_benefit_type` so you can confirm it in one glance.
--
-- To pin it for your database, run this once and look at which BenefitType your annual
-- maximums use, then add `AND b.BenefitType = <that value>` to the subquery below:
--
--     SELECT b.BenefitType, b.TimePeriod, b.CovCatNum, COUNT(*) AS rows_,
--            MIN(b.MonetaryAmt) AS min_amt, MAX(b.MonetaryAmt) AS max_amt
--     FROM benefit b WHERE b.MonetaryAmt > 0
--     GROUP BY b.BenefitType, b.TimePeriod, b.CovCatNum ORDER BY rows_ DESC;
--
-- `insurance_paid_ytd` needs no such caveat: it is money actually received, summed from
-- claimproc.InsPayAmt, which is true regardless of any status enum.
-- Assumption: a calendar plan year. If the plan renews mid-year (insplan.MonthRenew > 0)
--   the YTD window below is wrong for it, which is why MonthRenew is in the output.
-- Read-only. Run in Reports > User Query.

SELECT
    pat.PatNum,
    CONCAT(pat.LName, ', ', pat.FName)                AS patient,
    pat.WirelessPhone,
    pat.HmPhone,
    pat.Email,
    car.CarrierName,
    ip.GroupName,
    ip.MonthRenew                                     AS plan_renews_month,
    amax.annual_max,
    amax.annual_max_benefit_type,
    ROUND(COALESCE(ytd.insurance_paid, 0), 2)         AS insurance_paid_ytd,
    ROUND(amax.annual_max - COALESCE(ytd.insurance_paid, 0), 2) AS remaining,
    (SELECT COUNT(*) FROM appointment ap
      WHERE ap.PatNum      = pat.PatNum
        AND ap.AptStatus  IN (1, 4)
        AND ap.AptDateTime >= CURDATE())              AS currently_booked,
    (SELECT ROUND(SUM(pl.ProcFee), 2) FROM procedurelog pl
      WHERE pl.PatNum     = pat.PatNum
        AND pl.ProcStatus = 1)                        AS treatment_planned_value
FROM patplan pp
    INNER JOIN patient pat ON pat.PatNum     = pp.PatNum
    INNER JOIN inssub  s   ON s.InsSubNum    = pp.InsSubNum
    INNER JOIN insplan ip  ON ip.PlanNum     = s.PlanNum
    LEFT  JOIN carrier car ON car.CarrierNum = ip.CarrierNum
    INNER JOIN (
        -- largest plan-level monetary benefit with no coverage category
        SELECT b.PlanNum,
               MAX(b.MonetaryAmt) AS annual_max,
               MIN(b.BenefitType) AS annual_max_benefit_type
        FROM benefit b
        WHERE b.MonetaryAmt > 0
          AND b.CovCatNum   = 0
        GROUP BY b.PlanNum
    ) amax ON amax.PlanNum = ip.PlanNum
    LEFT JOIN (
        SELECT cp.PatNum, cp.PlanNum, SUM(cp.InsPayAmt) AS insurance_paid
        FROM claimproc cp
        WHERE cp.InsPayAmt > 0
          AND cp.DateCP BETWEEN MAKEDATE(YEAR(CURDATE()), 1) AND CURDATE()
        GROUP BY cp.PatNum, cp.PlanNum
    ) ytd ON ytd.PatNum = pat.PatNum AND ytd.PlanNum = ip.PlanNum
WHERE pat.PatStatus = 0                               -- 0 = Patient (active)
  AND (s.DateTerm = '0001-01-01' OR s.DateTerm >= CURDATE())   -- coverage not terminated
  AND amax.annual_max - COALESCE(ytd.insurance_paid, 0) > 0
ORDER BY remaining DESC;
