-- What actually came in the door, by day and by provider. Production is what you did;
-- this is what you were paid. Splits are the truth here, not `payment`, because one
-- payment can be split across several patients and providers.
-- Assumption: a paysplit with UnearnedType = 0 is earned income. Non-zero UnearnedType is
--   prepayment / unearned and is reported separately below rather than silently mixed in.
-- Read-only. Run in Reports > User Query. Edit the two dates.

SELECT
    ps.DatePay                                                         AS pay_date,
    COALESCE(NULLIF(prov.Abbr, ''), CONCAT(prov.LName, ' ', prov.FName),
             '(unassigned)')                                           AS provider,
    COUNT(DISTINCT ps.PayNum)                                          AS payments,
    ROUND(SUM(CASE WHEN ps.UnearnedType = 0 THEN ps.SplitAmt ELSE 0 END), 2) AS earned,
    ROUND(SUM(CASE WHEN ps.UnearnedType <> 0 THEN ps.SplitAmt ELSE 0 END), 2) AS unearned_prepayment,
    ROUND(SUM(ps.SplitAmt), 2)                                         AS total_collected
FROM paysplit ps
    LEFT JOIN provider prov ON prov.ProvNum = ps.ProvNum
WHERE ps.DatePay BETWEEN '2026-09-01' AND '2026-09-30'
GROUP BY ps.DatePay, provider
ORDER BY ps.DatePay, total_collected DESC;
