# Open Dental report queries

Read-only SQL for [Open Dental](https://www.opendental.com/), written to answer questions
that practices have actually asked in public and that were never answered.

Every query in this repository is **executed against Open Dental's real schema before it
ships**. Not "should work" — run, by [`verify.sh`](verify.sh), on every push.

## How to use one

1. Open the `.sql` file and read the header. It states the assumption the query makes
   about your question, and marks the literals you should edit.
2. In Open Dental: **Reports > User Query**, paste, run.
3. Everything here is `SELECT` only. Nothing writes, updates or deletes.

No download, no add-on, no remote access, and no patient data leaves your building.

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
| [09 recall due, nothing booked](queries/09-recall-due-not-booked.sql) | Patients overdue for recall with no future appointment — the reactivation list |
| [10 insurance claims outstanding](queries/10-insurance-claims-outstanding.sql) | Claims sent and still unpaid, aged 0-30 / 31-60 / 61-90 / 90+ |

## Why these ones

Open Dental's own documentation says custom query requests have a backlog of
"several weeks", and directs people to hire a third-party query writer. Support staff
decline to write custom SQL on the forum, for a good reason — every practice's workflow
is different. So the questions sit there. Several of the threads these answer had **zero
replies for over a year**.

## Verifying it yourself

```bash
./verify.sh            # needs docker + python3
OD_VERSION=25-1 ./verify.sh   # check against a different Open Dental version
```

It downloads Open Dental's published documentation XML, builds a structure-only database
from it (430 tables, no data), runs every query, and fails on any error.

## Version differences

Written against **Open Dental 26.2**. Column names move occasionally between versions.
If a query errors on yours, run `verify.sh` with your version number — it will tell you
exactly which column is the problem. Open an issue with the error and I'll fix it.

## Ask for a report

**[Request one here](../../issues/new?template=query-request.md)** — say what number you
want in plain English and include your Open Dental version. Real questions get real queries
added to this repo, free. That is how most of the ones above got written.

If it's a big one and you'd rather not wait your turn, I write these to order —
**[$150, tested, inside 48 hours](https://ishubham8.gumroad.com/l/imidn)**, or $450 for
three. Delivered as a `.sql` file you run yourself, so no patient data leaves your office
and there's nothing to sign. If it doesn't answer the question you asked, I fix it or
refund you.

But ask in an issue first — most requests turn out to be quick and free.

---

Maintained by Shubham Gautam · [ishubham2101@gmail.com](mailto:ishubham2101@gmail.com)
I also write these to order when it's faster than doing it yourself.
