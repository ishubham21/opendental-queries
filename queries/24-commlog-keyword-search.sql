-- Search every communication note for a phrase, across all patients at once.
-- Answers forum t=7903, "Keyword match in commlog query".
-- The Commlog window searches one patient at a time, which is no help when the question
--   is "who did we tell about the fee increase" or "which patients mentioned the new
--   insurance". This searches the lot.
-- Assumption: commlog.Note holds the text. CommType is a foreign key into `definition`,
--   so the type name is joined rather than printed as a number.
-- Read-only. Run in Reports > User Query. Edit the phrase and the date window.

SELECT
    cl.CommDateTime,
    pat.PatNum,
    CONCAT(pat.LName, ', ', pat.FName)                       AS patient,
    pat.WirelessPhone,
    COALESCE(NULLIF(def.ItemName, ''), CONCAT('Type ', cl.CommType)) AS comm_type,
    CASE cl.SentOrReceived WHEN 1 THEN 'Sent' WHEN 2 THEN 'Received' ELSE '' END AS direction,
    COALESCE(NULLIF(u.UserName, ''), '')                     AS entered_by,
    cl.Note
FROM commlog cl
    INNER JOIN patient    pat ON pat.PatNum   = cl.PatNum
    LEFT  JOIN definition def ON def.DefNum   = cl.CommType
    LEFT  JOIN userod     u   ON u.UserNum    = cl.UserNum
WHERE cl.Note LIKE '%fee increase%'        -- <-- edit this
  AND cl.CommDateTime >= '2026-01-01'      -- <-- keep the window tight, commlog is large
ORDER BY cl.CommDateTime DESC;
