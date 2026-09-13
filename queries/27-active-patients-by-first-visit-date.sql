-- Active patients whose first visit was before a date you choose.
-- Answers forum t=7681, "Active patients with first visit before date".
-- Useful for anniversary lists, for working out how much of the chart predates a transition,
--   and for any question shaped like "how many of our patients have been with us since X".
-- The trap is patient.DateFirstVisit. Open Dental sets it on the first completed procedure,
--   but it is an editable field, and on a converted database it is often either blank or the
--   conversion date for the entire chart. So this reports it next to the real first completed
--   procedure date, and flags the rows where they disagree by more than a month.
-- Assumption: active means PatStatus = 0. That excludes inactive, archived, deceased and
--   prospective. See notes/status-codes-that-break-reports.md for what each value means.
-- Read-only. Run in Reports > User Query. Edit the cutoff date.

SELECT
    pat.PatNum,
    CONCAT(pat.LName, ', ', pat.FName)      AS patient,
    pat.Birthdate,
    CASE WHEN YEAR(pat.DateFirstVisit) < 1880 THEN ''
         ELSE CAST(pat.DateFirstVisit AS CHAR) END AS first_visit_field,
    first_proc.first_completed              AS first_completed_procedure,
    CASE WHEN YEAR(pat.DateFirstVisit) < 1880 THEN 'field never set'
         WHEN first_proc.first_completed IS NULL THEN 'no completed procedures'
         WHEN ABS(DATEDIFF(pat.DateFirstVisit, first_proc.first_completed)) > 31
              THEN 'field and procedures disagree'
         ELSE '' END                        AS check_this,
    TIMESTAMPDIFF(YEAR, first_proc.first_completed, CURDATE()) AS years_with_practice,
    last_proc.last_completed                AS last_completed_procedure,
    COALESCE(NULLIF(prov.Abbr, ''), '')     AS primary_provider
FROM patient pat
    LEFT JOIN (
        SELECT pl.PatNum, MIN(pl.ProcDate) AS first_completed
        FROM procedurelog pl
        WHERE pl.ProcStatus = 2 AND YEAR(pl.ProcDate) > 1880
        GROUP BY pl.PatNum
    ) first_proc ON first_proc.PatNum = pat.PatNum
    LEFT JOIN (
        SELECT pl.PatNum, MAX(pl.ProcDate) AS last_completed
        FROM procedurelog pl
        WHERE pl.ProcStatus = 2 AND YEAR(pl.ProcDate) > 1880
        GROUP BY pl.PatNum
    ) last_proc ON last_proc.PatNum = pat.PatNum
    LEFT JOIN provider prov ON prov.ProvNum = pat.PriProv
WHERE pat.PatStatus = 0
  AND COALESCE(first_proc.first_completed, pat.DateFirstVisit) < '2020-01-01'   -- <-- edit this
  AND YEAR(COALESCE(first_proc.first_completed, pat.DateFirstVisit)) > 1880
ORDER BY COALESCE(first_proc.first_completed, pat.DateFirstVisit);

-- To count rather than list, replace the whole SELECT list with COUNT(*) and drop the ORDER BY.
-- To use the DateFirstVisit field alone and ignore the procedure history, change the WHERE to
--   `pat.PatStatus = 0 AND YEAR(pat.DateFirstVisit) > 1880 AND pat.DateFirstVisit < '2020-01-01'`.
