-- Appointments in a date range for one provider, with broken appointments excluded.
-- Answers forum t=8306: "all of the broken appointments are included... just get the
--   appointments shown which has NOT been broken?"
-- Edit the three literals marked below. Set @ProvNum to 0 for all providers.
-- Read-only. Run in Reports > User Query.

SELECT
    ap.AptDateTime,
    prov.Abbr                   AS provider,
    pat.PatNum,
    pat.LName,
    pat.FName,
    ap.ClinicNum,
    CASE ap.AptStatus
        WHEN 1 THEN 'Scheduled'
        WHEN 2 THEN 'Complete'
        WHEN 3 THEN 'UnschedList'
        WHEN 4 THEN 'ASAP'
        WHEN 6 THEN 'Planned'
    END                         AS apt_status,
    ap.ProcDescript,
    ap.Note
FROM appointment ap
    INNER JOIN patient  pat  ON pat.PatNum  = ap.PatNum
    LEFT  JOIN provider prov ON prov.ProvNum = ap.ProvNum
WHERE ap.AptDateTime >= '2026-01-01'        -- <-- start date: edit this
  AND ap.AptDateTime <  '2026-02-01'        -- <-- end date (exclusive): edit this
  AND ap.AptStatus   <> 5                   -- 5 = Broken. This is the whole point.
  -- One provider only? Uncomment the next line and put their ProvNum in.
  -- AND ap.ProvNum   =  3                   -- <-- provider: find it in Lists > Providers
ORDER BY ap.AptDateTime;
