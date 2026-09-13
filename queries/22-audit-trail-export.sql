-- The audit trail as a table you can export, filtered to one date range.
-- Answers forum t=8548, "How can I export an audit trail?".
-- Open Dental's Audit Trail window shows this per patient. This gives the whole range at
--   once, with the username resolved, which is what you need for a review or a dispute.
-- Assumption: securitylog.PermType identifies the permission that was exercised. It is a
--   numeric code and the meaning is version-specific, so it is reported as a number
--   alongside LogText rather than translated. LogText is the human-readable line Open
--   Dental itself wrote, and it is the column to read.
-- WARNING: securitylog is large in an established practice. Keep the window narrow, and
--   add a PatNum filter if you are investigating one chart.
-- Read-only. Run in Reports > User Query. Edit the two dates.

SELECT
    sl.LogDateTime,
    COALESCE(NULLIF(u.UserName, ''), CONCAT('UserNum ', sl.UserNum)) AS username,
    sl.PermType,
    sl.CompName                                  AS workstation,
    sl.PatNum,
    CONCAT(COALESCE(pat.LName, ''), ', ', COALESCE(pat.FName, '')) AS patient,
    sl.LogText
FROM securitylog sl
    LEFT JOIN userod  u   ON u.UserNum   = sl.UserNum
    LEFT JOIN patient pat ON pat.PatNum  = sl.PatNum
WHERE sl.LogDateTime BETWEEN '2026-09-01 00:00:00' AND '2026-09-30 23:59:59'
ORDER BY sl.LogDateTime DESC;
