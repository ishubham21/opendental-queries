-- Case acceptance by provider: of what was diagnosed in a window, how much got done.
-- Measured in dollars, not procedure counts, because one crown is not one sealant.
-- Assumption: a procedure diagnosed in the window counts to the provider who planned it,
--   and counts as accepted once its status is Complete (2) regardless of when it was done.
--   ProcStatus 1 = treatment planned, 2 = complete, 6 = deleted (never counted).
-- Read-only. Run in Reports > User Query. Edit the two dates.

SELECT
    COALESCE(NULLIF(prov.Abbr, ''), CONCAT(prov.LName, ' ', prov.FName),
             '(unassigned)')                                              AS provider,
    COUNT(*)                                                              AS procedures_diagnosed,
    ROUND(SUM(pl.ProcFee), 2)                                             AS diagnosed_value,
    SUM(CASE WHEN pl.ProcStatus = 2 THEN 1 ELSE 0 END)                    AS procedures_accepted,
    ROUND(SUM(CASE WHEN pl.ProcStatus = 2 THEN pl.ProcFee ELSE 0 END), 2) AS accepted_value,
    ROUND(100 * SUM(CASE WHEN pl.ProcStatus = 2 THEN pl.ProcFee ELSE 0 END)
              / NULLIF(SUM(pl.ProcFee), 0), 1)                            AS acceptance_pct_by_value
FROM procedurelog pl
    LEFT JOIN provider prov ON prov.ProvNum = pl.ProvNum
WHERE pl.ProcStatus IN (1, 2)                 -- still planned, or done. 6 = deleted.
  AND pl.DateTP     <> '0001-01-01'
  AND pl.DateTP BETWEEN '2026-01-01' AND '2026-09-30'
GROUP BY provider
ORDER BY diagnosed_value DESC;
