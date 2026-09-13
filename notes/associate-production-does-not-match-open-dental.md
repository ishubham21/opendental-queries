# Why your associate's production number does not match Open Dental's report

This comes up every time an associate is paid on a percentage, and it has been asked on the
Open Dental forum and left unanswered for years. The dentist's own tally and the report
disagree, usually by thousands a month, and neither side is doing arithmetic wrong.

There are four places the two numbers come apart. Only the last one is a real disagreement.

## 1. Hygiene billed under the dentist's licence

In most practices hygiene is performed by a hygienist but **billed under a supervising
dentist's provider number**, because that is what the payer requires. Open Dental records
this faithfully: `procedurelog.ProvNum` is who it was billed under.

So a report grouped by `ProvNum` credits the dentist with the hygienist's fluoride, x-rays
and prophy. If the associate's contract says "my production", the two of you probably do
not mean the same thing by it, and neither of you is wrong. The contract is ambiguous.

The fix is not to pick a side. It is to show both, and then have the conversation:

```sql
SELECT
    prov.Abbr                                                            AS provider,
    DATE_FORMAT(pl.ProcDate, '%Y-%m')                                    AS month,
    ROUND(SUM(pl.ProcFee), 2)                                            AS total_production,
    ROUND(SUM(CASE WHEN pc.IsHygiene = 1 THEN pl.ProcFee ELSE 0 END), 2) AS hygiene_production,
    ROUND(SUM(CASE WHEN pc.IsHygiene = 0 THEN pl.ProcFee ELSE 0 END), 2) AS dentist_production
FROM procedurelog pl
    INNER JOIN procedurecode pc   ON pc.CodeNum  = pl.CodeNum
    INNER JOIN provider      prov ON prov.ProvNum = pl.ProvNum
WHERE pl.ProcStatus = 2                     -- 2 = Complete
  AND pl.ProcDate  >= '2026-01-01'
  AND pl.ProcDate  <  '2027-01-01'
GROUP BY prov.ProvNum, prov.Abbr, DATE_FORMAT(pl.ProcDate, '%Y-%m')
ORDER BY month, total_production DESC;
```

`procedurecode.IsHygiene` is the flag that separates them. The full file, with comments, is
[`queries/06-production-by-dentist-including-hygiene.sql`](../queries/06-production-by-dentist-including-hygiene.sql).

## 2. Deleted procedures are still in the table

`ProcStatus = 6` is deleted. The row does not disappear; it sits there with its fee intact.
Any production query that does not filter on status reports work that was cancelled,
sometimes months of it. This is the single most common reason a hand-written production
number comes back too high.

`ProcStatus = 2` is complete. That is the only status a production figure should count.
Treatment-planned (`1`) is a different report and a different conversation.

## 3. Production is not collections

`procedurelog.ProcFee` is what was charged. It is not what was collected, and it is not net
of writeoffs. A PPO writeoff can be 30 to 40% of the fee and it never appears in a production
report, which is why a practice can hit its production goal and still be short on cash.

If the contract pays on **collections**, production is the wrong table entirely; the figure
lives in `paysplit`, not `procedurelog`. Those are different numbers with different
timings, and paying a percentage of one while quoting the other is how these arguments
start.

## 4. The date the work counts on

`ProcDate` is the date of service. If your month-end runs on entry date, or the procedure
was completed in one month and dated into another, the totals shift between periods. Pick
one and write it into the contract.

## The short version

Before anyone argues about the number, agree on four things in writing:

1. Does "production" include hygiene billed under the licence?
2. Is it production or collections?
3. Are writeoffs deducted?
4. Which date does the work count on?

Most associate-compensation disputes are one of those four, and none of them is a software
problem.

## Related

- [Nineteen free, tested Open Dental queries](../README.md)
- [Why future payment-plan charges are missing from your query](why-future-payplan-charges-are-missing.md)
- [Can you do this for ClearDent / Tracker / Dentrix / Eaglesoft?](other-practice-management-systems.md)

Every query referenced here is executed against a 430-table replica of Open Dental's real
schema, built from Open Dental's own published documentation, before it ships and again on
every change.
