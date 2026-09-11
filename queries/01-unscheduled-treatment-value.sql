-- Unscheduled treatment: diagnosed work nobody has booked, in dollars.
-- Question answered: "How much treatment have we diagnosed that is not on the schedule?"
-- Assumption: "unscheduled" = treatment-planned, not attached to any appointment
--   (neither a real appointment nor a planned one). Change MinFee to taste.
-- Read-only. Run in Reports > User Query.

SELECT
    pat.PatNum,
    pat.LName,
    pat.FName,
    pat.WirelessPhone,
    pat.HmPhone,
    pat.ClinicNum,
    COUNT(pl.ProcNum)                      AS procs_unscheduled,
    ROUND(SUM(pl.ProcFee), 2)              AS dollars_unscheduled,
    MIN(pl.DateTP)                         AS first_diagnosed,
    MAX(pl.DateTP)                         AS last_diagnosed
FROM procedurelog pl
    INNER JOIN patient pat ON pat.PatNum = pl.PatNum
WHERE pl.ProcStatus     = 1      -- 1 = TP (treatment planned).  6 = deleted, never include.
  AND pl.AptNum         = 0      -- not attached to an appointment
  AND pl.PlannedAptNum  = 0      -- and not on a planned appointment either
  AND pl.ProcFee        > 0
  AND pat.PatStatus     = 0      -- 0 = Patient (active). Excludes archived/deleted/deceased.
GROUP BY pat.PatNum, pat.LName, pat.FName, pat.WirelessPhone, pat.HmPhone, pat.ClinicNum
HAVING dollars_unscheduled >= 200          -- <-- MinFee: edit this
ORDER BY dollars_unscheduled DESC;
