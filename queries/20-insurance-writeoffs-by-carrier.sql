-- What each carrier writes off, which is the number missing from every production report.
-- Answers forum t=7952, "Insurance payments and writeoff reports".
-- Production reports count procedurelog.ProcFee, the full fee. A PPO writeoff is the
--   difference between that and what the contract allows, and it never appears there.
--   That is how a practice hits its production goal and is still short on cash.
-- Assumption: claimproc.WriteOff is the contractual adjustment on a received claim line.
--   Rows with WriteOff = 0 are excluded because they are not writeoffs.
-- Read-only. Run in Reports > User Query. Edit the two dates.

SELECT
    car.CarrierName,
    ip.GroupName,
    COUNT(DISTINCT cp.ClaimNum)                        AS claims,
    COUNT(*)                                           AS claim_lines,
    ROUND(SUM(cp.FeeBilled), 2)                        AS billed,
    ROUND(SUM(cp.InsPayAmt), 2)                        AS insurance_paid,
    ROUND(SUM(cp.WriteOff), 2)                         AS written_off,
    ROUND(100 * SUM(cp.WriteOff) / NULLIF(SUM(cp.FeeBilled), 0), 1)
                                                       AS writeoff_pct_of_billed,
    ROUND(SUM(cp.FeeBilled) - SUM(cp.InsPayAmt) - SUM(cp.WriteOff), 2)
                                                       AS left_for_the_patient
FROM claimproc cp
    LEFT JOIN insplan ip  ON ip.PlanNum     = cp.PlanNum
    LEFT JOIN carrier car ON car.CarrierNum = ip.CarrierNum
WHERE cp.WriteOff  <> 0
  AND cp.DateCP    <> '0001-01-01'
  AND cp.DateCP BETWEEN '2026-01-01' AND '2026-09-30'
GROUP BY car.CarrierName, ip.GroupName
ORDER BY written_off DESC;
