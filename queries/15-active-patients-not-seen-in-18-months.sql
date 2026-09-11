-- Active patients with no completed treatment in 18 months and nothing on the books.
-- Different from the recall query (09): this catches people who fell off entirely,
-- including those who never had a recall row to go overdue in the first place.
-- Read-only. Run in Reports > User Query. Change the interval to taste.

SELECT
    pat.PatNum,
    CONCAT(pat.LName, ', ', pat.FName)   AS patient,
    pat.WirelessPhone,
    pat.HmPhone,
    pat.Email,
    pat.Birthdate,
    last_seen.last_visit,
    DATEDIFF(CURDATE(), last_seen.last_visit) AS days_since_last_visit,
    COALESCE(NULLIF(prov.Abbr, ''), CONCAT(prov.LName, ' ', prov.FName)) AS primary_provider
FROM patient pat
    LEFT JOIN provider prov ON prov.ProvNum = pat.PriProv
    INNER JOIN (
        SELECT PatNum, MAX(ProcDate) AS last_visit
        FROM procedurelog
        WHERE ProcStatus = 2                    -- 2 = Complete
          AND ProcDate  <> '0001-01-01'
        GROUP BY PatNum
    ) last_seen ON last_seen.PatNum = pat.PatNum
WHERE pat.PatStatus       = 0                   -- 0 = Patient (active)
  AND last_seen.last_visit < CURDATE() - INTERVAL 18 MONTH
  AND NOT EXISTS (
        SELECT 1 FROM appointment ap
        WHERE ap.PatNum      = pat.PatNum
          AND ap.AptStatus  IN (1, 4)           -- scheduled or ASAP
          AND ap.AptDateTime >= CURDATE())
ORDER BY last_seen.last_visit ASC;
