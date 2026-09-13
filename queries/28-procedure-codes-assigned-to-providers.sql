-- Which procedure codes have a default provider set, and which providers are being defaulted to.
-- Answers forum t=7680, "query for codes assigned to providers".
-- procedurecode.ProvNumDefault overrides the patient's primary provider when a procedure is
--   entered. It is how a practice makes every prophy land on hygiene, or every implant land on
--   the specialist, without anybody remembering to change the provider dropdown.
-- It is also the quietest source of wrong production numbers in Open Dental, because nothing in
--   the interface lists the overrides. One code pointed at a provider who left two years ago will
--   keep assigning production to them, and the only symptom is a number that looks slightly off.
-- This lists every override, and marks the ones pointing at a provider who is hidden or has a
--   termination date in the past. It does not read provider.ProvStatus, because Open Dental does
--   not publish what its values mean and I am not going to guess at one in a query you will run
--   against a live database.
-- Read-only. Run in Reports > User Query.

SELECT
    pc.ProcCode,
    pc.Descript                                  AS description,
    pc.AbbrDesc                                  AS abbreviation,
    COALESCE(NULLIF(cat.ItemName, ''), CONCAT('Category ', pc.ProcCat)) AS category,
    CASE pc.IsHygiene WHEN 1 THEN 'Yes' ELSE '' END AS flagged_hygiene,
    prov.ProvNum                                 AS default_prov_num,
    COALESCE(NULLIF(prov.Abbr, ''), CONCAT(prov.LName, ' ', prov.FName)) AS defaults_to,
    CASE WHEN prov.ProvNum IS NULL THEN 'provider record missing'
         WHEN prov.IsHidden = 1     THEN 'provider is hidden'
         WHEN prov.DateTerm IS NOT NULL AND YEAR(prov.DateTerm) > 1880
              AND prov.DateTerm < CURDATE() THEN CONCAT('provider left ', prov.DateTerm)
         ELSE '' END                             AS check_this
FROM procedurecode pc
    LEFT JOIN provider   prov ON prov.ProvNum = pc.ProvNumDefault
    LEFT JOIN definition cat  ON cat.DefNum   = pc.ProcCat
WHERE pc.ProvNumDefault > 0
ORDER BY
    CASE WHEN prov.ProvNum IS NULL OR prov.IsHidden = 1 THEN 0 ELSE 1 END,
    defaults_to,
    pc.ProcCode;

-- The other half of the same question is which codes have no override, which is most of them.
-- Swap the WHERE for `pc.ProvNumDefault = 0` and drop the provider columns.
--
-- If what you actually want is who performed the work rather than who is defaulted to, that is
-- procedurelog.ProvNum on the completed procedures, not this table. Query 06 does that.
