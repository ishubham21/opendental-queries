-- New patients who came in, had work done, and left with nothing on the books.
-- Answers forum t=8618: "a list of new patients who visited the office for the first
--   time, completed at least one procedure, but left without having any appointments created"
-- Assumption: "new" = first visit within the last N days. Edit the 180 below.
-- Read-only. Run in Reports > User Query.

SELECT
    pat.PatNum,
    pat.LName,
    pat.FName,
    pat.WirelessPhone,
    pat.Email,
    pat.DateFirstVisit,
    pat.ClinicNum,
    COUNT(pl.ProcNum)          AS completed_procs,
    ROUND(SUM(pl.ProcFee), 2)  AS completed_dollars,
    MAX(pl.ProcDate)           AS last_completed
FROM patient pat
    INNER JOIN procedurelog pl
            ON  pl.PatNum     = pat.PatNum
            AND pl.ProcStatus = 2          -- 2 = Complete
WHERE pat.PatStatus      = 0               -- active patients only
  AND pat.DateFirstVisit >= CURDATE() - INTERVAL 180 DAY   -- <-- "new" window: edit this
  AND NOT EXISTS (
        SELECT 1
        FROM appointment ap
        WHERE ap.PatNum      = pat.PatNum
          AND ap.AptStatus  IN (1, 4)      -- something still on the books
          AND ap.AptDateTime > NOW()
  )
GROUP BY pat.PatNum, pat.LName, pat.FName, pat.WirelessPhone, pat.Email,
         pat.DateFirstVisit, pat.ClinicNum
ORDER BY completed_dollars DESC;
