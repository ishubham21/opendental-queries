# Why future payment-plan charges are missing from your query

If you query `payplancharge` for a payment plan and get fewer rows than the Open Dental
GUI shows you, your query is probably correct and **the rows genuinely do not exist yet**.

## What is actually happening

On a **dynamic** payment plan, Open Dental does not store future charges as `payplancharge`
rows. It calculates them for display, and materialises a row when the charge actually comes
due. So the GUI can show a schedule that no query will return, because most of it is not
data. It is arithmetic.

This is also why the API's `getExpected` returns nothing. It is not implemented, and it
would have to compute rather than fetch. Open Dental support have confirmed this on the
forum, with no ETA.

## How to tell the difference

`payplan.IsDynamic` tells you which kind of plan you are looking at. On a fixed plan the
charge rows exist up front. On a dynamic one they appear over time.

## Reconciling remaining months against remaining charges

Common in ortho: you want remaining treatment months versus remaining scheduled charges.
You have to project the schedule yourself from `payplan`: `NumberOfPayments`, `PayAmt`,
`ChargeFrequency`, `DatePayPlanStart`, then subtract the charges that already exist.

[`queries/08-payment-plan-charges-including-future.sql`](../queries/08-payment-plan-charges-including-future.sql)
does both halves in one result. The two columns that matter:

```sql
COUNT(*) OVER (PARTITION BY pp.PayPlanNum)                        AS charge_rows_that_exist,
pp.NumberOfPayments - COUNT(*) OVER (PARTITION BY pp.PayPlanNum)  AS charge_rows_not_yet_created
```

Anything dated in the future that *does* appear is a real, materialised row rather than a
projection.

## Two practical notes

- Window functions need MySQL 8 / MariaDB 10.2 or later. Recent Open Dental versions are
  fine; on an older server, replace the two `OVER()` columns with a join to a grouped
  subquery over `payplancharge`.
- `IsClosed = 0` restricts the result to open plans. Drop it if you want closed ones too.

---
Part of [opendental-queries](../README.md), read-only reporting SQL for Open Dental,
every query executed against the vendor's published schema before it ships.
