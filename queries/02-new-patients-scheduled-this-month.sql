-- New patients SCHEDULED this month (not the ones already seen).
-- Answers forum t=8634: "How do I see how many new patients are scheduled this month
--   instead of how many new patients I seen so far this month"
-- Assumption: a new-patient appointment is one flagged IsNewPatient on the appointment
--   itself, which is what the Appointment Book sets. Status 1 = Scheduled, 4 = ASAP.
-- Read-only. Run in Reports > User Query.

SELECT
    ap.AptDateTime,
    pat.PatNum,
    pat.LName,
    pat.FName,
    pat.WirelessPhone,
    prov.Abbr                              AS provider,
    ap.ClinicNum,
    CASE ap.AptStatus WHEN 1 THEN 'Scheduled' WHEN 4 THEN 'ASAP' END AS apt_status
FROM appointment ap
    INNER JOIN patient  pat  ON pat.PatNum  = ap.PatNum
    LEFT  JOIN provider prov ON prov.ProvNum = ap.ProvNum
WHERE ap.IsNewPatient = 1
  AND ap.AptStatus   IN (1, 4)             -- on the books (scheduled or ASAP)
  AND ap.AptDateTime >= DATE_FORMAT(CURDATE(), '%Y-%m-01')
  AND ap.AptDateTime <  DATE_FORMAT(CURDATE(), '%Y-%m-01') + INTERVAL 1 MONTH
ORDER BY ap.AptDateTime;
