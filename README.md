# Open Dental report queries

Read-only SQL for [Open Dental](https://www.opendental.com/), written from questions
practices have actually asked in public.

Every query in this repository is **executed against Open Dental's real schema before it
ships**. Not "should work". Run, by [`verify.sh`](verify.sh), on every push.

## Read this before you read the rest

Open Dental publishes its own
[Query Examples library](https://opendentalsoft.com:1943/ODQueryList/QueryList.aspx),
which is free, public, and holds over a thousand queries. It is a bigger library than this
one and you should look there too. **This README said these answered questions that "were
never answered", and that was wrong**: several here have an official equivalent, including
the discount plan list, procedure codes with a default provider, patients with remaining
benefits, and time clock hours. I had not checked before writing that, and checking took
ten minutes.

What is actually different here, and it is worth something:

- **Every query is run against the schema before it ships**, by CI, on every push. The
  official library's own page says "There may be additional changes needed to return the
  results you want" and sorts by age because older ones may no longer run.
- **Each one states the assumption that makes it wrong.** A deleted procedure still sits in
  `procedurelog` with `ProcStatus` 6, a never-terminated date is `0001-01-01` rather than
  NULL, hygiene billed under a licence lands on the wrong provider. That is the part that
  quietly breaks a number, and bare SQL does not tell you about it.
- **These are written against 26.2**, the current version.

If a query here and a query there both answer your question, use theirs. It is free too and
it has been in use longer.

## How to use one

1. Open the `.sql` file and read the header. It states the assumption the query makes
   about your question, and marks the literals you should edit.
2. In Open Dental: **Reports > User Query**, paste, run.
3. Everything here is `SELECT` only. Nothing writes, updates or deletes.

No download, no add-on, no remote access, and no patient data leaves your building.

## The one that isn't here

Most of these exist because somebody asked. If the number you want is not below, say what
it is in plain English. You do not have to phrase it like a database question, and
include your Open Dental version from **Help > About**:

**[Ask for a query](../../issues/new?template=query-request.md)** is free, and it gets added
here so the next person does not have to ask.

If you do not have a GitHub account and do not want one, email **ishubham2101@gmail.com**
instead. Same thing, no signup. Four days of this repository being public have produced
eight visitors and zero issues, which I suspect says more about asking a dentist to open a
GitHub account than it does about whether anybody wants the queries.

Real questions I have written for so far: production by dentist with hygiene billed under
their licence rolled in, payment plans aged to a date in the past, insurance benefits still
unspent before the plan year closes. Nothing exotic; they were just numbers Open Dental's
standard reports would not give in that shape.

## The queries

| File | Answers |
|---|---|
| [01 unscheduled treatment value](queries/01-unscheduled-treatment-value.sql) | How much treatment have we diagnosed that nobody has booked? |
| [02 new patients scheduled this month](queries/02-new-patients-scheduled-this-month.sql) | New patients *scheduled* this month, not the ones already seen |
| [03 new patients with no follow-up](queries/03-new-patients-no-followup-appointment.sql) | New patients who had work done and left with nothing on the books |
| [04 appointments excluding broken](queries/04-appointments-excluding-broken.sql) | An appointment report by date range and provider, with broken appointments out |
| [05 daily production goal vs scheduled](queries/05-daily-production-goal-vs-scheduled.sql) | Scheduled production against a goal you set per weekday |
| [06 production by dentist including hygiene](queries/06-production-by-dentist-including-hygiene.sql) | Production by dentist, with hygiene billed under their licence rolled in |
| [07 payment plans aging as of a date](queries/07-payment-plans-aging-as-of-date.sql) | Payment plans with principal, charged, paid and due as of a date |
| [08 payment plan charges including future](queries/08-payment-plan-charges-including-future.sql) | Why future payment-plan charges are missing from your query, and what to do |
| [09 recall due, nothing booked](queries/09-recall-due-not-booked.sql) | Patients overdue for recall with no future appointment, the reactivation list |
| [10 insurance claims outstanding](queries/10-insurance-claims-outstanding.sql) | Claims sent and still unpaid, aged 0-30 / 31-60 / 61-90 / 90+ |
| [11 A/R aging by patient](queries/11-accounts-receivable-aging-by-patient.sql) | Accounts receivable by guarantor in 0-30 / 31-60 / 61-90 / 90+ buckets |
| [12 collections by day and provider](queries/12-collections-by-day-and-provider.sql) | What you were actually paid, by day and provider, with prepayments kept separate |
| [13 broken appointments, repeat offenders](queries/13-broken-appointments-repeat-offenders.sql) | Who keeps breaking appointments, and how many chair hours it cost |
| [14 case acceptance by provider](queries/14-treatment-plan-acceptance-by-provider.sql) | Of what each provider diagnosed, how much got done, measured in dollars |
| [15 active patients not seen in 18 months](queries/15-active-patients-not-seen-in-18-months.sql) | Patients who fell off entirely, including those with no recall row to go overdue |
| [16 unused insurance benefits this year](queries/16-unused-insurance-benefits-this-year.sql) | Who still has annual maximum left before the plan year closes, the Q4 call list |
| [17 hours worked by employee and day](queries/17-hours-worked-by-employee-and-day.sql) | The timecard as a table: clocked, overtime, adjustments and paid hours per person per day |
| [18 patients by insurance carrier](queries/18-patients-by-insurance-carrier.sql) | Everyone currently covered by one carrier, with plan, group and subscriber |
| [19 same-day treatment completed](queries/19-same-day-treatment-completed.sql) | Work diagnosed and completed in the same visit, by provider, the same-day-dentistry number |
| [20 insurance writeoffs by carrier](queries/20-insurance-writeoffs-by-carrier.sql) | What each carrier writes off, which is the number every production report leaves out |
| [21 payments by type](queries/21-payments-by-type.sql) | Payments split by type with the names resolved, not left as integers |
| [22 audit trail export](queries/22-audit-trail-export.sql) | The whole audit trail for a date range, with usernames resolved |
| [23 fee schedule export](queries/23-fee-schedule-export.sql) | One fee schedule as a table, for comparing a PPO offer against your own |
| [24 commlog keyword search](queries/24-commlog-keyword-search.sql) | Search every communication note for a phrase, across all patients at once |
| [25 collections waterfall](queries/25-collections-waterfall.sql) | How much of each month's production has been collected since, and how long it took |
| [26 patients on a discount plan](queries/26-patients-on-a-discount-plan.sql) | Who is on which discount plan, read from the subscription table and cross-checked against the legacy field |
| [27 active patients by first visit date](queries/27-active-patients-by-first-visit-date.sql) | Active patients whose first visit predates a date, with the DateFirstVisit field checked against the real procedure history |
| [28 procedure codes assigned to providers](queries/28-procedure-codes-assigned-to-providers.sql) | Every code with a default provider override, and which ones point at someone who has left |
| [29 discount plan profitability](queries/29-discount-plan-profitability.sql) | Production, plan writeoffs, adjustments and payments for discount plan patients over a date range. The one on this list with no official equivalent |
| [30 call list by carrier and code range](queries/30-recall-list-by-carrier-and-code-range.sql) | Patients on one carrier with planned work in a code range, with last visit, next visit, provider, the plan in priority order and their preferred call times |

## Why these ones

Open Dental's own documentation says custom query requests have a backlog of
"several weeks", and directs people to hire a third-party query writer. Support staff
decline to write custom SQL on the forum, for a good reason, because every practice's workflow
is different. So the questions sit there. Several of the threads these answer had **zero
replies for over a year**.

## Verifying it yourself

```bash
./verify.sh            # needs docker + python3
OD_VERSION=25-1 ./verify.sh   # check against a different Open Dental version
```

It downloads Open Dental's published documentation XML, builds a structure-only database
from it (430 tables, no data), runs every query, and fails on any error.

For a system that does **not** publish a schema, such as ClearDent, Tracker, Dentrix or Eaglesoft,
[`schema-replica.sh`](schema-replica.sh) does the same job from an `INFORMATION_SCHEMA`
dump of your own database, which contains structure only and no patient data:

```bash
./schema-replica.sh your-dump.csv queries/
```

See [the note on other practice-management systems](notes/other-practice-management-systems.md).

## Version differences

Written against **Open Dental 26.2**. Column names move occasionally between versions.
If a query errors on yours, run `verify.sh` with your version number. It will tell you
exactly which column is the problem. Open an issue with the error and I'll fix it.

## Notes

- [Getting User Query results into Excel without the rows breaking](notes/getting-query-results-into-excel.md).
  Two opposite faults that look identical: a note whose newlines survive and break the row
  apart, and a note whose newlines are stripped when you wanted to keep them. Both have a
  fix, and both belong in your SQL rather than in Open Dental.
- [The Open Dental status codes that silently break a report](notes/status-codes-that-break-reports.md).
  `ProcStatus`, `AptStatus` and `PatStatus` decoded, what each wrong value does to a
  number, and the query that confirms the mapping against your own database.
- [Why your associate's production number does not match Open Dental's report](notes/associate-production-does-not-match-open-dental.md).
  Hygiene billed under a licence, deleted procedures that are still in the table,
  production versus collections, and which date the work counts on.
- [Can you do this for ClearDent / Tracker / Dentrix / Eaglesoft?](notes/other-practice-management-systems.md).
  No other system publishes its schema, so here is the one read-only query that makes
  your database describe itself, and a standing offer to write the first query free for
  any system somebody sends a structure dump for.
- [Why future payment-plan charges are missing from your query](notes/why-future-payplan-charges-are-missing.md).
  Dynamic plans do not store future charges as rows, which is why `payplancharge` and the
  API's `getExpected` both come back short.

## Ask for a report

**[Request one here](../../issues/new?template=query-request.md)**. Say what number you
want in plain English and include your Open Dental version. Real questions get real queries
added to this repo, free. That is how most of the ones above got written.

If it's a big one and you'd rather not wait your turn, I write these to order.
**[$150, tested, inside 48 hours](https://ishubham8.gumroad.com/l/imidn)**, or $450 for
three. Delivered as a `.sql` file you run yourself, so no patient data leaves your office
and there's nothing to sign. If it doesn't answer the question you asked, I fix it or
refund you.

But ask in an issue first, because most requests turn out to be quick and free.

---

Maintained by Shubham Gautam · [ishubham2101@gmail.com](mailto:ishubham2101@gmail.com)
I also write these to order when it's faster than doing it yourself.
