# "Can you do this for ClearDent / Tracker / Dentrix / Eaglesoft?"

Short answer: not blind, and it is worth knowing why, because the reason is the whole
difference between Open Dental and everything else.

## Why Open Dental is easy and the others are not

Open Dental does two things almost no other practice-management system does:

1. It **publishes its complete database schema**, every table and column for every
   version, as a public XML file.
2. It ships **Reports > User Query**, a window that runs read-only SQL against your own
   server.

That combination is why every query in this repository can be executed against a 430-table
replica of the real schema before it ships, and why you can paste one in and have it work.

ClearDent, Tracker, Dentrix, Eaglesoft and the rest publish no schema. Writing a query for
them from the outside means guessing table and column names, and **you** would be the one
finding out the guess was wrong. So I don't.

## What actually works instead

Every one of these systems sits on a SQL database that can describe itself. One query
returns the shape of the database and **no data at all**. No patient names, no clinical
information, no financials. Just table names, column names and types.

**SQL Server** (Dentrix, Eaglesoft, ClearDent on-premise and most Windows-based systems):

```sql
SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
ORDER BY TABLE_NAME, ORDINAL_POSITION;
```

**MySQL / MariaDB** (Open Dental itself, and some others):

```sql
SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
ORDER BY TABLE_NAME, ORDINAL_POSITION;
```

**Oracle** (a few older systems):

```sql
SELECT table_name, column_name, data_type
FROM user_tab_columns
ORDER BY table_name, column_id;
```

Export the result as CSV. That file is better than a published schema, because it is *your*
version rather than a document that may lag it.

## What I do with it, and how to run it yourself

[`schema-replica.sh`](../schema-replica.sh) in this repository takes that CSV, maps the
SQL Server and Oracle type spellings MariaDB will not accept, builds the replica in Docker,
and runs every `.sql` in a directory against it:

```bash
./schema-replica.sh your-dump.csv queries/
```

A query referencing a column your database does not have fails there with
`Unknown column`, instead of failing in front of you. It is the same harness `verify.sh`
uses for Open Dental, with the schema coming from your dump instead of a vendor XML.

Build a structure-only replica, the same thing `verify.sh` does for Open Dental, except
the schema comes from your dump instead of a vendor XML. A query can then be proven to
run before anyone pastes it into a live system. A column that does not exist fails on my
machine rather than on yours.

The parts that take actual work, and that a guess always gets wrong:

- **How the system marks a deleted or voided procedure.** In Open Dental that is
  `ProcStatus = 6`. Forget to exclude it and every production and treatment-planned figure
  comes back inflated. Every system has an equivalent, and every system hides it somewhere
  different.
- **How a procedure is linked to an appointment**: directly, through a junction table, or
  not at all until it is completed.
- **Which status codes mean "on the books"** as opposed to broken, cancelled or on an
  unscheduled list.

## Before you run anything

- Check whether your agreement with the vendor says anything about direct database access.
- If you are on a **hosted** product rather than on-premise, you probably cannot reach the
  database at all, and this is a dead end, so ask the vendor for a reporting export instead.
- Ask your vendor rep for a **read-only** login rather than going around them. It is a
  normal request and it is the clean way to do it.

## Standing offer

**The first practice on each system that sends me a structure dump gets one query written
for that system free, and I publish it here so nobody else has to ask.** Open Dental has
twenty-five; every other system has zero, and that is a silly place for this to stop.

Open an issue, or email ishubham2101@gmail.com.
