# Getting User Query results into Excel without the rows breaking

Four unanswered threads on the Open Dental forum touch this: `t=8573` (line breaks lost in
the User Query export to XLS), `t=7715` (columns overlapping in query reports), `t=8118`
(Excel refreshable reports), `t=7438` (query automation).

The first two look like the same complaint and are **opposite** problems, which is worth
saying because I got it wrong on the first pass. `t=7715` is a note whose newlines survive
into the export and break the row apart. `t=8573` is a note whose newlines are stripped and
the poster wants them kept. Both come from the same place: a line-delimited export has no
way to carry a newline inside a field, so it either breaks or it flattens.

## If the line breaks are being stripped and you want them back (t=8573)

The export writes one line per row, so a newline inside a note would end the row early.
Rather than produce a broken file, the export removes them, and the note arrives in Excel as
one run-on paragraph.

You cannot make the export carry them. What you can do is carry a marker through and turn it
back into a real line break in Excel, which takes about ten seconds:

```sql
REPLACE(REPLACE(REPLACE(pl.ClaimNote, '\r\n', '~~'), '\n', '~~'), '\r', '~~') AS note
```

Then in Excel, select the note column and open Find & Replace. Find `~~`. In the Replace
field press **Ctrl+J**, which inserts a line break character and will look like an empty
box. Replace All, then turn on Wrap Text for the column.

Pick a marker that cannot occur in your notes. `~~` is usually safe; `|` is not, people use
it in notes more than you would think.

## Why rows break apart in the export (t=7715)

A `Note` column contains newlines. `procedurelog.ClaimNote`, `commlog.Note`,
`patient.AddrNote`, `appointment.Note` and `insplan.PlanNote` all routinely hold text
somebody typed across several lines.

The export writes one line per row. A newline inside a field ends the line early, so the
rest of that field becomes a new row with its columns shifted left. One note with three
line breaks turns one row into four broken ones, and the damage looks like a column
alignment bug rather than a data problem, which is why it gets reported as one.

## The fix, in the query

Flatten the field before it leaves the database:

```sql
REPLACE(REPLACE(REPLACE(cl.Note, '\r\n', ' '), '\n', ' '), '\r', ' ') AS note
```

Nest all three. Windows text uses `\r\n`, Unix uses `\n`, and older Mac text uses `\r`.
Replacing only `\n` leaves a stray carriage return that some spreadsheet importers still
treat as a line ending.

Tabs cause the same problem in a tab-separated export, so if your note fields might
contain them:

```sql
REPLACE(REPLACE(REPLACE(REPLACE(cl.Note, '\r\n', ' '), '\n', ' '), '\r', ' '), '\t', ' ') AS note
```

If a note is long enough to be unwieldy in a cell, truncate it deliberately rather than
letting the export decide:

```sql
LEFT(REPLACE(REPLACE(cl.Note, '\r\n', ' '), '\n', ' '), 300) AS note_start
```

## The other thing that shifts columns

A value containing the delimiter. A practice name like `Smith, Jones & Partners` in a
comma-separated export does the same damage as a newline. If you are exporting to CSV
rather than tab-separated, either quote the field or replace the commas:

```sql
REPLACE(pat.LName, ',', '') AS last_name
```

Every query in this repository already avoids this where it can, which is why several of
them build display names with `CONCAT` rather than exporting raw fields.

## Refreshable reports and automation

`t=8118` and `t=7438` ask for something different: a spreadsheet that updates itself, or a
query that runs on a schedule.

Open Dental's User Query window runs a query when you press the button. It is not a
scheduler and it does not publish anything Excel can poll. What people do instead is
connect Excel or a reporting tool directly to the MySQL database with a **read-only**
account, and point the refresh at that.

I am not going to walk you through granting database access, because how that should be
done depends on your server, your network and your obligations around patient data, and
getting it wrong is worse than running a query by hand. Two things worth saying plainly:

- The account should be read-only. A reporting tool has no business holding credentials
  that can write to a live practice database.
- The connection should not cross the open internet without a tunnel or a VPN.

If you want the shape of it, ask your IT provider for a read-only MySQL user restricted to
your own network, and give them the query. That is a small, specific request they will
recognise, which is much easier to get done than "can we connect Excel to the server".

## Related

- [Twenty-five free, tested Open Dental queries](../README.md)
- [The Open Dental status codes that silently break a report](status-codes-that-break-reports.md)
