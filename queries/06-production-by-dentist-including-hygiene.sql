-- Completed production by provider, splitting out hygiene work billed under a licence.
-- Answers forum t=7966: production by dentist that includes the hygiene revenue
--   (fluoride, x-rays) billed under that dentist's licence, for associate/partner comp.
-- Assumption: procedurelog.ProvNum is who the procedure is billed under, which is the
--   number comp is calculated on. procedurecode.IsHygiene marks the hygiene codes.
-- Read-only. Run in Reports > User Query.

SELECT
    prov.Abbr                                                        AS provider,
    prov.LName,
    prov.FName,
    DATE_FORMAT(pl.ProcDate, '%Y-%m')                                AS month,
    ROUND(SUM(pl.ProcFee), 2)                                        AS total_production,
    ROUND(SUM(CASE WHEN pc.IsHygiene = 1 THEN pl.ProcFee ELSE 0 END), 2) AS hygiene_production,
    ROUND(SUM(CASE WHEN pc.IsHygiene = 0 THEN pl.ProcFee ELSE 0 END), 2) AS dentist_production,
    COUNT(pl.ProcNum)                                                AS procs
FROM procedurelog pl
    INNER JOIN procedurecode pc ON pc.CodeNum = pl.CodeNum
    INNER JOIN provider     prov ON prov.ProvNum = pl.ProvNum
WHERE pl.ProcStatus = 2                    -- 2 = Complete
  AND pl.ProcDate  >= '2026-01-01'         -- <-- start date: edit this
  AND pl.ProcDate  <  '2027-01-01'         -- <-- end date (exclusive): edit this
GROUP BY prov.ProvNum, prov.Abbr, prov.LName, prov.FName, DATE_FORMAT(pl.ProcDate, '%Y-%m')
ORDER BY month, total_production DESC;
