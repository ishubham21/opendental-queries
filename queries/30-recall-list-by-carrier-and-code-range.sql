-- Active patients on one insurance carrier, with treatment planned inside a code range,
--   showing last visit, next visit, primary provider, the planned work in priority order,
--   and a commlog note of one chosen type.
-- Answers forum t=7837, which had been sitting with zero replies since August 2022.
-- This is a call list. The point is that one person can work down it with a phone, so every
--   column on it has to be something you would say or need while the phone is ringing.
--
-- FIVE THINGS THAT BITE HERE, in the order they will bite you.
--
-- 1. The carrier join is four tables deep and it is easy to join the wrong one.
--    patient -> patplan -> inssub -> insplan -> carrier. Joining insplan straight to patient
--    does not work; there is no link. patplan.Ordinal = 1 is the primary plan, and without
--    that filter a patient with two plans appears twice.
--
-- 2. Procedure codes are strings, so BETWEEN 'D0120' AND 'D1120' is a string comparison.
--    That happens to behave for same-length D codes, which is why it looks fine, but it also
--    catches anything alphabetically between them. Check the code list it returns before you
--    trust the range.
--
-- 3. GROUP_CONCAT has a length limit, 1024 characters by default. A patient with a large
--    treatment plan silently loses the end of their list, with no error and no warning. The
--    SET below raises it for this session only and changes nothing permanently.
--
-- 4. Priority is a foreign key into the definition table, not a number you can sort on.
--    ORDER BY procedurelog.Priority sorts by DefNum, which is creation order, not the order
--    the priorities appear in your list. Joining definition and sorting on ItemOrder is what
--    gives the sequence the treatment plan actually shows.
--
-- 5. Next visit is not simply the next appointment row. AptStatus 5 is broken and 6 is
--    unscheduled, and counting either as a booked visit puts people on the call list who
--    should be at the top of it. Only AptStatus 1 scheduled and 4 ASAP count as booked.
--
-- Read-only. Run in Reports > User Query. Edit the carrier, the code range and the note type.

SET SESSION group_concat_max_len = 100000;
SET @Carrier   = '%Delta Care%';       -- <-- edit, matched with LIKE against carrier.CarrierName
SET @CodeFrom  = 'D4100';              -- <-- edit
SET @CodeTo    = 'D4999';              -- <-- edit
SET @NoteType  = 'Preferred Appointment Times';   -- <-- edit, matched against the commlog type name

SELECT
    pat.PatNum,
    CONCAT(pat.LName, ', ', pat.FName)                     AS patient,
    pat.WirelessPhone,
    car.CarrierName                                        AS carrier,
    last_seen.last_visit,
    next_apt.next_visit,
    COALESCE(NULLIF(prov.Abbr, ''), CONCAT(prov.LName, ' ', prov.FName)) AS primary_provider,
    tp.planned_value,
    tp.planned_work,
    note.preferred_times
FROM patient pat
    INNER JOIN patplan pp  ON pp.PatNum    = pat.PatNum AND pp.Ordinal = 1
    INNER JOIN inssub  isb ON isb.InsSubNum = pp.InsSubNum
    INNER JOIN insplan ip  ON ip.PlanNum    = isb.PlanNum
    INNER JOIN carrier car ON car.CarrierNum = ip.CarrierNum
    LEFT JOIN provider prov ON prov.ProvNum = pat.PriProv
    -- the treatment planned work inside the code range, one row per patient
    INNER JOIN (
        SELECT pl.PatNum,
               ROUND(SUM(pl.ProcFee), 2) AS planned_value,
               GROUP_CONCAT(CONCAT(pc.ProcCode, ' ', COALESCE(NULLIF(pc.AbbrDesc,''), pc.Descript))
                            ORDER BY COALESCE(pri.ItemOrder, 999), pl.ProcDate SEPARATOR ' | ') AS planned_work
        FROM procedurelog pl
            INNER JOIN procedurecode pc  ON pc.CodeNum = pl.CodeNum
            LEFT  JOIN definition    pri ON pri.DefNum = pl.Priority
        WHERE pl.ProcStatus = 1                       -- treatment planned, not completed, not deleted
          AND pc.ProcCode BETWEEN @CodeFrom AND @CodeTo
        GROUP BY pl.PatNum
    ) tp ON tp.PatNum = pat.PatNum
    LEFT JOIN (
        SELECT pl.PatNum, MAX(pl.ProcDate) AS last_visit
        FROM procedurelog pl
        WHERE pl.ProcStatus = 2 AND YEAR(pl.ProcDate) > 1880
        GROUP BY pl.PatNum
    ) last_seen ON last_seen.PatNum = pat.PatNum
    LEFT JOIN (
        SELECT a.PatNum, MIN(a.AptDateTime) AS next_visit
        FROM appointment a
        WHERE a.AptStatus IN (1, 4) AND a.AptDateTime >= NOW()
        GROUP BY a.PatNum
    ) next_apt ON next_apt.PatNum = pat.PatNum
    LEFT JOIN (
        SELECT cl.PatNum,
               GROUP_CONCAT(cl.Note ORDER BY cl.CommDateTime DESC SEPARATOR ' | ') AS preferred_times
        FROM commlog cl
            INNER JOIN definition d ON d.DefNum = cl.CommType
        WHERE d.ItemName = @NoteType
        GROUP BY cl.PatNum
    ) note ON note.PatNum = pat.PatNum
WHERE pat.PatStatus = 0
  AND car.CarrierName LIKE @Carrier
ORDER BY next_apt.next_visit IS NOT NULL, tp.planned_value DESC;

-- The ORDER BY puts patients with nothing booked at the top, then sorts by how much planned
-- work they have. That is the order you want to make the calls in.
--
-- If the commlog column comes back empty, your note type is almost certainly named something
-- else. This lists every commlog type name your database actually has, without needing to
-- know which definition category they live in:
--   SELECT DISTINCT d.DefNum, d.Category, d.ItemName
--   FROM commlog cl INNER JOIN definition d ON d.DefNum = cl.CommType
--   ORDER BY d.ItemName;
-- I am reading it back off your own commlog rather than hardcoding a category number,
-- because Open Dental does not publish what the category numbers mean and a guessed one
-- would send you looking in the wrong list.
