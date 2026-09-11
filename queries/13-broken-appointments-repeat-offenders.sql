-- Patients who repeatedly break appointments, with what it cost you in scheduled time.
-- Use before you decide who gets a same-day-only slot or a deposit.
-- AptStatus 5 = Broken (the same value query 04 excludes). Counted over a window you set.
-- Read-only. Run in Reports > User Query.

SELECT
    pat.PatNum,
    CONCAT(pat.LName, ', ', pat.FName)              AS patient,
    pat.WirelessPhone,
    pat.HmPhone,
    COUNT(*)                                        AS broken_appointments,
    MIN(ap.AptDateTime)                             AS first_broken,
    MAX(ap.AptDateTime)                             AS last_broken,
    -- Pattern is one character per 5 minutes of chair time
    ROUND(SUM(CHAR_LENGTH(ap.Pattern)) * 5 / 60, 1) AS chair_hours_lost,
    (SELECT COUNT(*) FROM appointment a2
      WHERE a2.PatNum     = pat.PatNum
        AND a2.AptStatus IN (1, 4)
        AND a2.AptDateTime >= CURDATE())            AS currently_booked
FROM appointment ap
    INNER JOIN patient pat ON pat.PatNum = ap.PatNum
WHERE ap.AptStatus   = 5                            -- 5 = Broken
  AND ap.AptDateTime >= CURDATE() - INTERVAL 18 MONTH
  AND pat.PatStatus  = 0                            -- 0 = Patient (active)
GROUP BY pat.PatNum, patient, pat.WirelessPhone, pat.HmPhone
HAVING broken_appointments >= 2
ORDER BY broken_appointments DESC, chair_hours_lost DESC;
