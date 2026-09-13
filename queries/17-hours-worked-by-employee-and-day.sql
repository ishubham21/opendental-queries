-- Hours worked per employee per day, from the time clock. Asked three separate times on
-- the Open Dental forum (t=8547 "How can i see what days I worked?", t=8311 "Export hours
-- worked each day", t=8117 "Timecard total monthly report") and never answered with SQL.
-- Assumption: TimeDisplayed1/2 are the clock-in and clock-out as shown on the timecard.
--   they are the adjusted values, which is what payroll is actually run from. TimeEntered1/2
--   are the raw punches, so use those instead if you are auditing rather than paying.
--   Rows still open (no clock-out yet) are excluded rather than counted as zero.
-- Adjust and OTimeHours are already in hours and are shown separately so the arithmetic
--   is visible rather than buried.
-- Read-only. Run in Reports > User Query. Edit the two dates.

SELECT
    emp.EmployeeNum,
    CONCAT(emp.LName, ', ', emp.FName)                                   AS employee,
    DATE(ce.TimeDisplayed1)                                              AS work_date,
    MIN(ce.TimeDisplayed1)                                               AS first_in,
    MAX(ce.TimeDisplayed2)                                               AS last_out,
    ROUND(SUM(TIMESTAMPDIFF(SECOND, ce.TimeDisplayed1, ce.TimeDisplayed2)) / 3600, 2)
                                                                         AS clocked_hours,
    ROUND(SUM(COALESCE(ce.OTimeHours, 0)), 2)                            AS overtime_hours,
    ROUND(SUM(COALESCE(ce.Adjust, 0)), 2)                                AS adjustment_hours,
    ROUND(SUM(TIMESTAMPDIFF(SECOND, ce.TimeDisplayed1, ce.TimeDisplayed2)) / 3600
          + SUM(COALESCE(ce.Adjust, 0)), 2)                              AS paid_hours,
    COUNT(*)                                                             AS punches
FROM clockevent ce
    INNER JOIN employee emp ON emp.EmployeeNum = ce.EmployeeNum
WHERE ce.TimeDisplayed1 >= '2026-09-01'      -- <-- start date: edit this
  AND ce.TimeDisplayed1 <  '2026-10-01'      -- <-- end date (exclusive): edit this
  AND ce.TimeDisplayed2 >  ce.TimeDisplayed1 -- exclude rows still clocked in
GROUP BY emp.EmployeeNum, employee, DATE(ce.TimeDisplayed1)
ORDER BY employee, work_date;
