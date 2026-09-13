-- New patients in a date range, counted correctly.
-- This is a corrected rewrite of Open Dental's own library query #1203, which a user
--   reported as dropping new patients in forum t=8218 in March 2024. The Query Team replied
--   that they were rewriting it and that the reporter's suggested fix would not work. They
--   were right on both counts, and neither the explanation nor the fix was ever posted.
--
-- WHY #1203 MISSES PATIENTS
--   The original ends with:
--       GROUP BY pls.PatNum
--       HAVING pls.ProcDate = MIN(pls.ProcDate) AND pls.ProcDate BETWEEN @Start AND @End
--   With GROUP BY PatNum, the bare column `pls.ProcDate` is not the group's minimum. It is
--   whichever row of the group MySQL happened to keep, and that choice is not defined. So
--   `HAVING pls.ProcDate = MIN(pls.ProcDate)` passes only when the row MySQL kept happens to
--   be the earliest one. When it is not, the patient fails the test and vanishes from the
--   count entirely. That is the whole bug, and it is why the same database can give
--   different answers to #1203 and to #1645.
--   MySQL 5.7 and later reject this outright under ONLY_FULL_GROUP_BY. Open Dental ships
--   with that mode off, so instead of an error you get a quietly wrong number.
--
--   REPRODUCED, not reasoned about. On MariaDB 11 with sql_mode as Open Dental ships it, the
--   bare column resolves to the first physically stored row of the group. Five test patients,
--   two of whom had their later procedure stored before their earlier one:
--       PatNum  bare column  real MIN     fate
--       100     2026-09-01   2026-09-01   kept
--       200     2026-09-05   2026-09-05   kept
--       300     2026-09-03   2026-09-03   kept
--       400     2026-09-25   2026-09-02   DROPPED
--       500     2026-09-28   2026-09-04   DROPPED
--   Both dropped patients are genuinely new inside the window. Rows land out of date order in
--   any real database, from back-dating, re-entry and conversions, which is why the count is
--   wrong by an amount nobody can predict. The query below returns all five.
--
-- WHY THE SUGGESTED FIX IS NOT ENOUGH
--   Changing the HAVING to `MIN(pl.ProcDate) BETWEEN @Start AND @End` does fix the patient
--   set: it tests the group's real minimum. But the SELECT still carries bare ProcDate and
--   ProvNum, so the date and the provider reported for each new patient are still taken from
--   an arbitrary row. You get the right list of people with the wrong details beside them.
--   The suggested fix also introduces a new bug of its own: `pc.ProcCode NOT IN (@ignoreCodes)`
--   where @ignoreCodes holds the single string 'D9986,D9987'. That compares against one value
--   containing a comma, so it excludes nothing at all. A MySQL user variable cannot be used
--   as an IN list.
--
-- WHAT THIS DOES INSTEAD
--   Finds each patient's first completed procedure date in a subquery, joins back to the row
--   or rows on that date, and picks one deterministically. The tie-break is stated rather
--   than left to the engine: when a patient has several procedures on their first day, the
--   lowest ProcNum wins, which is the first one entered.
-- Read-only. Run in Reports > User Query.

SET @StartDate = CURDATE() - INTERVAL 1 MONTH;   -- <-- edit
SET @EndDate   = CURDATE();                      -- <-- edit

SELECT
    'NP'                                   AS CountType,
    pl.ProcDate                            AS first_visit,
    pl.PatNum,
    pl.ProvNum,
    COALESCE(NULLIF(prov.Abbr, ''), '')    AS provider,
    CONCAT(pat.LName, ', ', pat.FName)     AS patient
FROM procedurelog pl
    INNER JOIN patient  pat  ON pat.PatNum  = pl.PatNum
    LEFT  JOIN provider prov ON prov.ProvNum = pl.ProvNum
    INNER JOIN (
        -- one row per patient: their first completed procedure, and which row it was
        SELECT g.PatNum, g.first_date, MIN(pl3.ProcNum) AS first_proc
        FROM (
            SELECT pl2.PatNum, MIN(pl2.ProcDate) AS first_date
            FROM procedurelog pl2
                INNER JOIN procedurecode pc2 ON pc2.CodeNum = pl2.CodeNum
            WHERE pl2.ProcStatus = 2
              AND pc2.ProcCode NOT IN ('D9986', 'D9987')   -- literals, not a variable
              AND YEAR(pl2.ProcDate) > 1880                -- keep the 0001-01-01 sentinel out of MIN
            GROUP BY pl2.PatNum
        ) g
        INNER JOIN procedurelog  pl3 ON pl3.PatNum = g.PatNum AND pl3.ProcDate = g.first_date
        INNER JOIN procedurecode pc3 ON pc3.CodeNum = pl3.CodeNum
        WHERE pl3.ProcStatus = 2 AND pc3.ProcCode NOT IN ('D9986', 'D9987')
        GROUP BY g.PatNum, g.first_date
    ) f ON f.PatNum = pl.PatNum AND f.first_proc = pl.ProcNum
WHERE f.first_date BETWEEN @StartDate AND @EndDate
ORDER BY pl.ProcDate, patient;

-- For the count rather than the list, wrap it:
--   SELECT COUNT(*) FROM ( ...the query above without the ORDER BY... ) x;
--
-- D9986 and D9987 are missed and cancelled appointments. They are excluded because a patient
-- whose first record is a missed appointment has not actually been seen, and counting them
-- as a new patient inflates the number and dates them to the wrong month.
