-- Payments split by type, with the type names resolved rather than left as numbers.
-- Answers forum t=8175, "How can I FIlter by PayType?".
-- payment.PayType is a foreign key into `definition`, not a fixed enum, so the types are
--   whatever the practice set up. Category 10 is the payment-type list. Joining to
--   definition is the difference between a readable report and a column of integers.
-- Assumption: reporting on `payment` rather than `paysplit`, so this is what was taken at
--   the front desk. For income attributed to a provider, use query 12 instead.
-- Read-only. Run in Reports > User Query. Edit the two dates.

SELECT
    COALESCE(NULLIF(def.ItemName, ''), CONCAT('PayType ', pay.PayType)) AS payment_type,
    COUNT(*)                                    AS payments,
    ROUND(SUM(pay.PayAmt), 2)                   AS total,
    ROUND(AVG(pay.PayAmt), 2)                   AS average,
    ROUND(SUM(pay.MerchantFee), 2)              AS merchant_fees,
    MIN(pay.PayDate)                            AS first_payment,
    MAX(pay.PayDate)                            AS last_payment
FROM payment pay
    LEFT JOIN definition def ON def.DefNum = pay.PayType
WHERE pay.PayDate BETWEEN '2026-01-01' AND '2026-09-30'
GROUP BY payment_type, pay.PayType
ORDER BY total DESC;
