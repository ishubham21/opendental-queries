-- Insurance claims sent and still unpaid, aged. Where practice money actually gets stuck.
-- Assumption: a claimproc row with Status = 1 (sent/pending) and no insurance payment yet
--   is outstanding. Aged from DateCP, the claim procedure date.
-- Read-only. Run in Reports > User Query.

SELECT
    car.CarrierName,
    pat.PatNum,
    pat.LName,
    pat.FName,
    cp.ClaimNum,
    cp.DateCP                              AS claim_date,
    DATEDIFF(CURDATE(), cp.DateCP)         AS days_outstanding,
    CASE
        WHEN DATEDIFF(CURDATE(), cp.DateCP) <=  30 THEN '0-30'
        WHEN DATEDIFF(CURDATE(), cp.DateCP) <=  60 THEN '31-60'
        WHEN DATEDIFF(CURDATE(), cp.DateCP) <=  90 THEN '61-90'
        ELSE '90+'
    END                                    AS age_bucket,
    ROUND(SUM(cp.FeeBilled), 2)            AS billed,
    ROUND(SUM(cp.InsPayEst), 2)            AS estimated_from_insurance
FROM claimproc cp
    INNER JOIN patient pat ON pat.PatNum    = cp.PatNum
    LEFT  JOIN insplan ip  ON ip.PlanNum    = cp.PlanNum
    LEFT  JOIN carrier car ON car.CarrierNum = ip.CarrierNum
WHERE cp.Status     = 1                    -- sent / pending
  AND cp.InsPayAmt  = 0                    -- nothing received yet
  AND cp.DateCP    <> '0001-01-01'
  AND cp.DateCP    >= CURDATE() - INTERVAL 2 YEAR
GROUP BY car.CarrierName, pat.PatNum, pat.LName, pat.FName, cp.ClaimNum, cp.DateCP
ORDER BY days_outstanding DESC;
