-- Every active patient on a given carrier, with plan, group and subscriber.
-- Answers forum t=7858 "Query for accounts with particular insurance carrier".
-- Use it when a carrier changes its fee schedule, drops a plan, or goes out of network and
--   you need to know exactly who to call before they find out from the carrier.
-- Assumption: a patplan row is current coverage unless the subscription has been
--   terminated. Open Dental stores "never terminated" as the sentinel date 0001-01-01.
-- Read-only. Run in Reports > User Query. Edit the carrier name on the WHERE line.

SELECT
    car.CarrierName,
    ip.GroupName,
    ip.GroupNum,
    CASE pp.Ordinal WHEN 1 THEN 'Primary' WHEN 2 THEN 'Secondary' ELSE CONCAT('Ordinal ', pp.Ordinal) END
                                                    AS coverage,
    pat.PatNum,
    CONCAT(pat.LName, ', ', pat.FName)              AS patient,
    pat.WirelessPhone,
    pat.HmPhone,
    pat.Email,
    CONCAT(sub.LName, ', ', sub.FName)              AS subscriber,
    s.SubscriberID,
    s.DateEffective,
    s.DateTerm,
    (SELECT MAX(pl.ProcDate) FROM procedurelog pl
      WHERE pl.PatNum = pat.PatNum AND pl.ProcStatus = 2) AS last_visit
FROM patplan pp
    INNER JOIN patient pat ON pat.PatNum     = pp.PatNum
    INNER JOIN inssub  s   ON s.InsSubNum    = pp.InsSubNum
    INNER JOIN patient sub ON sub.PatNum     = s.Subscriber
    INNER JOIN insplan ip  ON ip.PlanNum     = s.PlanNum
    INNER JOIN carrier car ON car.CarrierNum = ip.CarrierNum
WHERE pat.PatStatus = 0                              -- 0 = Patient (active)
  AND car.CarrierName LIKE '%Delta%'                 -- <-- edit this
  AND (s.DateTerm = '0001-01-01' OR s.DateTerm >= CURDATE())
ORDER BY car.CarrierName, ip.GroupName, pat.LName, pat.FName;
