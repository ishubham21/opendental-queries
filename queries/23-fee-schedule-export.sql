-- One fee schedule as a table, with the procedure code, description and amount.
-- Answers forum t=8233, "Export and Import Fee Schedule".
-- Use it to compare a PPO schedule against your office schedule before you sign a
--   contract, or to hand an accountant the numbers without exporting patient data.
-- Assumption: fee.Amount is the fee for that code on that schedule. A code with no row
--   on the schedule is not listed, because Open Dental treats it as having no fee set
--   rather than a fee of zero, and those two mean different things.
-- Read-only. Run in Reports > User Query. Edit the schedule name.

SELECT
    fs.Description                       AS fee_schedule,
    pc.ProcCode,
    pc.Descript                          AS procedure_description,
    pc.AbbrDesc,
    ROUND(f.Amount, 2)                   AS fee,
    f.DateEffective,
    f.ClinicNum,
    f.ProvNum
FROM fee f
    INNER JOIN feesched      fs ON fs.FeeSchedNum = f.FeeSched
    INNER JOIN procedurecode pc ON pc.CodeNum     = f.CodeNum
WHERE fs.Description LIKE '%Office%'      -- <-- edit this, or drop the line for every schedule
  AND fs.IsHidden = 0
ORDER BY fs.Description, pc.ProcCode;
