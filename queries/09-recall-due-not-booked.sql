-- Patients whose recall (hygiene/perio) is due or overdue and who have nothing booked.
-- The reactivation list. Usually the fastest money in the database after unscheduled
-- treatment, because these are people who already accepted you as their dentist.
-- Assumption: "due" means recall.DateDue on or before today, the recall is not disabled,
--   and the patient has no future appointment that is actually on the books.
-- Read-only. Run in Reports > User Query.

SELECT
    pat.PatNum,
    pat.LName,
    pat.FName,
    pat.WirelessPhone,
    pat.HmPhone,
    pat.Email,
    pat.ClinicNum,
    rt.Description                       AS recall_type,
    r.DateDue,
    DATEDIFF(CURDATE(), r.DateDue)       AS days_overdue,
    r.DatePrevious                       AS last_done,
    (SELECT MAX(p2.ProcDate) FROM procedurelog p2
      WHERE p2.PatNum = pat.PatNum AND p2.ProcStatus = 2) AS last_completed_proc
FROM recall r
    INNER JOIN patient     pat ON pat.PatNum       = r.PatNum
    LEFT  JOIN recalltype  rt  ON rt.RecallTypeNum = r.RecallTypeNum
WHERE r.IsDisabled  = 0
  AND r.DateDue    <> '0001-01-01'
  AND r.DateDue    <= CURDATE()
  AND pat.PatStatus = 0                  -- active patients only
  AND NOT EXISTS (
        SELECT 1 FROM appointment ap
        WHERE ap.PatNum      = pat.PatNum
          AND ap.AptStatus  IN (1, 4)    -- scheduled or ASAP
          AND ap.AptDateTime > NOW()
  )
ORDER BY days_overdue DESC;
