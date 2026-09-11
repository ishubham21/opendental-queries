-- Accounts receivable by patient, in the standard 0-30 / 31-60 / 61-90 / 90+ buckets.
-- The report a practice asks for first, and the one Open Dental's own A/R screen is
-- slowest at when the guarantor list is long.
--
-- IMPORTANT, and the reason a naive version of this is wrong: the Bal_* columns on
--   `patient` are NOT live. Open Dental writes them during the aging run. If aging was
--   last run on the 1st, these numbers are as of the 1st, no matter what today's date is.
--   Check Tools > Aging, or look at the newest `DateLastAging` you have, before you act on
--   a number here. Everything below is exactly what the practice's own A/R report uses.
-- Assumption: balances are held at the guarantor, so rows are grouped by guarantor.
-- Read-only. Run in Reports > User Query.

SELECT
    guar.PatNum                                   AS guarantor_patnum,
    CONCAT(guar.LName, ', ', guar.FName)          AS guarantor,
    guar.WirelessPhone,
    guar.HmPhone,
    guar.Email,
    ROUND(guar.Bal_0_30,   2)                     AS bal_0_30,
    ROUND(guar.Bal_31_60,  2)                     AS bal_31_60,
    ROUND(guar.Bal_61_90,  2)                     AS bal_61_90,
    ROUND(guar.BalOver90,  2)                     AS bal_over_90,
    ROUND(guar.InsEst,     2)                     AS pending_insurance_estimate,
    ROUND(guar.BalTotal,   2)                     AS balance_total,
    ROUND(guar.BalTotal - guar.InsEst, 2)         AS patient_portion,
    guar.BillingType,
    (SELECT COUNT(*) FROM patient fam
      WHERE fam.Guarantor = guar.PatNum
        AND fam.PatStatus = 0)                    AS family_members
FROM patient guar
WHERE guar.PatNum    = guar.Guarantor   -- the guarantor is their own guarantor
  AND guar.BalTotal <> 0
ORDER BY guar.BalOver90 DESC, guar.BalTotal DESC;
