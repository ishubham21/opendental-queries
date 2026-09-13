-- Treatment that was diagnosed and completed on the same day, by provider.
-- Answers forum t=8254 "Query for TP Procedures Completed Same Day".
-- This is the same-day-dentistry number: work presented and accepted in the chair rather
--   than rescheduled. It is a different measure from overall case acceptance, because it
--   only counts what never had to be re-sold.
-- Assumption: DateTP is when the procedure was treatment-planned and ProcDate is when it
--   was completed. Same-day means those fall on the same date. ProcStatus 2 = Complete;
--   6 = deleted and is excluded by the status filter.
-- Read-only. Run in Reports > User Query. Edit the two dates.

SELECT
    COALESCE(NULLIF(prov.Abbr, ''), CONCAT(prov.LName, ' ', prov.FName), '(unassigned)')
                                                                          AS provider,
    DATE_FORMAT(pl.ProcDate, '%Y-%m')                                     AS month,
    COUNT(*)                                                              AS procedures_completed,
    SUM(CASE WHEN pl.DateTP = pl.ProcDate THEN 1 ELSE 0 END)              AS same_day_count,
    ROUND(SUM(pl.ProcFee), 2)                                             AS completed_value,
    ROUND(SUM(CASE WHEN pl.DateTP = pl.ProcDate THEN pl.ProcFee ELSE 0 END), 2)
                                                                          AS same_day_value,
    ROUND(100 * SUM(CASE WHEN pl.DateTP = pl.ProcDate THEN pl.ProcFee ELSE 0 END)
              / NULLIF(SUM(pl.ProcFee), 0), 1)                            AS same_day_pct_by_value
FROM procedurelog pl
    LEFT JOIN provider prov ON prov.ProvNum = pl.ProvNum
WHERE pl.ProcStatus = 2                       -- 2 = Complete
  AND pl.DateTP    <> '0001-01-01'            -- never treatment-planned: not a candidate
  AND pl.ProcDate BETWEEN '2026-01-01' AND '2026-09-30'
GROUP BY provider, DATE_FORMAT(pl.ProcDate, '%Y-%m')
ORDER BY month, same_day_value DESC;
