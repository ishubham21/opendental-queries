#!/usr/bin/env bash
# Build a structure-only replica of ANY practice-management database from an
# INFORMATION_SCHEMA dump, so a query can be proven to run before it is delivered.
#
# Open Dental publishes its schema, so verify.sh can fetch it. ClearDent, Tracker,
# Dentrix and the rest do not — but every one of them will answer:
#
#   SQL Server : SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS;
#   MySQL      : ...the same, WHERE TABLE_SCHEMA = DATABASE();
#
# That output is structure only — no patient data, no names, nothing clinical.
#
#   usage: schema-replica.sh <dump.csv|dump.tsv> [queries-dir]
set -euo pipefail
DUMP="${1:?schema dump (csv or tsv) with TABLE_NAME, COLUMN_NAME, DATA_TYPE}"
QDIR="${2:-}"
C=schema-replica
cleanup() { docker rm -f $C >/dev/null 2>&1 || true; }
trap cleanup EXIT

python3 - "$DUMP" /tmp/replica.sql <<'PY'
import csv, sys, re, collections

# SQL Server and Oracle spellings that MariaDB will not accept verbatim. Anything not
# listed falls through unchanged, and an unparseable type becomes TEXT rather than
# failing the build — the point is column NAMES, not exact storage.
MAP = {
    'nvarchar':'varchar(255)', 'nchar':'char(255)', 'varchar':'varchar(255)',
    'char':'char(255)', 'ntext':'text', 'uniqueidentifier':'char(36)',
    'datetime2':'datetime', 'smalldatetime':'datetime', 'datetimeoffset':'datetime',
    'money':'decimal(19,4)', 'smallmoney':'decimal(10,4)', 'bit':'tinyint(1)',
    'image':'longblob', 'varbinary':'blob', 'binary':'blob', 'xml':'text',
    'number':'decimal(38,10)', 'varchar2':'varchar(255)', 'nvarchar2':'varchar(255)',
    'clob':'longtext', 'blob':'blob', 'sql_variant':'text', 'hierarchyid':'text',
    'geography':'text', 'geometry':'text', 'rowversion':'binary(8)', 'timestamp':'datetime',
}

def norm(t):
    t = (t or '').strip().lower()
    base = re.split(r'[ (]', t)[0]
    if base in MAP: return MAP[base]
    if re.fullmatch(r'[a-z0-9_]+(\(\s*[-\d,\s]+\s*\))?', t): return t
    return 'text'

raw = open(sys.argv[1], newline='', encoding='utf-8-sig').read()
delim = '\t' if raw.count('\t') > raw.count(',') else ','
rows = list(csv.reader(raw.splitlines(), delimiter=delim))
if not rows: sys.exit('empty dump')

head = [h.strip().lower().replace(' ', '_') for h in rows[0]]
want = ('table_name', 'column_name', 'data_type')
if all(w in head for w in want):
    ti, ci, di = (head.index(w) for w in want)
    rows = rows[1:]
else:
    ti, ci, di = 0, 1, 2          # headerless: assume the documented column order

tables = collections.OrderedDict()
skipped = 0
for r in rows:
    if len(r) <= max(ti, ci, di): skipped += 1; continue
    t, c, d = r[ti].strip(), r[ci].strip(), r[di].strip()
    if not t or not c: skipped += 1; continue
    if not re.fullmatch(r'[A-Za-z0-9_$]+', t) or not re.fullmatch(r'[A-Za-z0-9_$]+', c):
        skipped += 1; continue     # a name that needs quoting is almost always a parse slip
    tables.setdefault(t, []).append((c, norm(d)))

out = []
for t, cols in tables.items():
    seen, uniq = set(), []
    for c, d in cols:
        if c.lower() in seen: continue
        seen.add(c.lower()); uniq.append((c, d))
    out.append("CREATE TABLE `%s` (\n%s\n);" % (t, ",\n".join("  `%s` %s" % cd for cd in uniq)))

open(sys.argv[2], 'w').write("\n".join(out) + "\n")
print("   %d tables, %d columns, %d rows skipped" %
      (len(tables), sum(len(v) for v in tables.values()), skipped))
if not tables: sys.exit("no tables parsed — check the dump's columns are TABLE_NAME, COLUMN_NAME, DATA_TYPE")
PY

echo "==> starting MariaDB"
cleanup
docker run -d --name $C -e MARIADB_ROOT_PASSWORD=r -e MARIADB_DATABASE=pms mariadb:11 >/dev/null
for i in $(seq 1 45); do docker exec $C mariadb -uroot -pr -e "SELECT 1" >/dev/null 2>&1 && break; sleep 2; done
docker exec -i $C mariadb -uroot -pr pms < /tmp/replica.sql
echo "==> replica built"

[ -z "$QDIR" ] && { echo "no queries directory given — replica built only"; exit 0; }
fail=0
for f in "$QDIR"/*.sql; do
  [ -e "$f" ] || continue
  if docker exec -i $C mariadb -uroot -pr pms < "$f" >/dev/null 2>/tmp/err; then
    echo "  PASS  $f"
  else
    echo "  FAIL  $f"; sed 's/^/        /' /tmp/err; fail=1
  fi
done
exit $fail
