# The Open Dental status codes that silently break a report

Almost every wrong number in a hand-written Open Dental query comes from one of three
columns. They are plain integers, the UI never shows them, and nothing errors when you get
one wrong — the report simply returns a different question's answer.

## Where these values come from, and how far to trust them

Open Dental publishes its **schema** (every table and column) but not an enum table for
these columns. The mapping below is taken from the order in which Open Dental's own **API
documentation** enumerates each status, corroborated against usage in Open Dental's public
forum. It matches every query in this repository.

**Confirm it against your own database before you rely on it.** One query does that, and it
is the honest first step for any of these:

```sql
SELECT ProcStatus, COUNT(*) AS rows_, ROUND(SUM(ProcFee),2) AS fees
FROM procedurelog GROUP BY ProcStatus ORDER BY ProcStatus;
```

Run the equivalent for `appointment.AptStatus` and `patient.PatStatus`. Then compare the
counts against what the matching Open Dental report shows for the same window. If the
buckets line up, the mapping holds for your version. If they do not, trust your database
over this page and tell me — I will correct it.

## `procedurelog.ProcStatus`

| value | meaning | what it does to a report |
|---|---|---|
| 1 | Treatment Planned (TP) | diagnosed, not done. **Production reports must exclude it.** |
| 2 | Complete (C) | done. The only status a production figure should count. |
| 3 | Existing Current Provider (EC) | pre-existing work, recorded for charting |
| 4 | Existing Other Provider (EO) | pre-existing, done elsewhere |
| 5 | Referred Out (R) | sent to a specialist |
| 6 | **Deleted (D)** | **still in the table, still carrying its fee** |
| 7 | Condition (Cn) | a condition, not a procedure |
| 8 | Treatment Plan inactive (TPi) | an inactive treatment plan |

**Status 6 is the expensive one.** A deleted procedure does not leave the table. Its
`ProcFee` sits there intact, and any production or unscheduled-treatment query that does
not filter on status counts work that was cancelled — sometimes months of it. This is the
single most common reason a hand-written production number comes back too high.

Statuses 3, 4 and 7 catch people out in the other direction: they are charting records, not
work you did, so a query that counts "everything except deleted" over-reports too.

## `appointment.AptStatus`

| value | meaning | notes |
|---|---|---|
| 1 | Scheduled | on the books |
| 2 | Complete | the patient came |
| 3 | UnschedList | on the unscheduled list — **not booked** |
| 4 | ASAP | on the books, flagged to move earlier |
| 5 | **Broken** | still a row in `appointment` |
| 6 | Planned | a planned appointment template, not a booking |

"On the books" is `AptStatus IN (1, 4)`. Not 3, which is the unscheduled list and is
precisely the set of people you are usually trying to *find*. Not 6, which is a template.

Status 5 is why an appointment report written by hand reads high: broken appointments are
still rows, and excluding them is usually the entire point of the report.

## `patient.PatStatus`

`0` is an active patient. Everything else — inactive, archived, deceased, prospective —
should normally be excluded from a recall, reactivation or A/R list. Sending a reactivation
postcard to a deceased patient is the sort of mistake that gets remembered.

## A fourth one, less known: `patient.Bal_*` is not live

`Bal_0_30`, `Bal_31_60`, `Bal_61_90`, `BalOver90` and `BalTotal` are **written by the aging
run**, not calculated when you query them. If aging last ran on the 1st, your A/R report is
as of the 1st no matter what today's date is, and a payment posted last Tuesday will not
show. Check when aging last ran before acting on any A/R figure, and especially before
sending statements off it.

## The general rule

If a number comes back higher than you expected, the first thing to check is whether a
status filter is missing. If it comes back lower, check whether the filter is too tight.
It is nearly always one of those two.

## Related

- [Sixteen free, tested Open Dental queries](../README.md) — every one states its
  assumption in the file header
- [Why your associate's production number does not match Open Dental's report](associate-production-does-not-match-open-dental.md)
- [Can you do this for ClearDent / Tracker / Dentrix / Eaglesoft?](other-practice-management-systems.md)
