#!/usr/bin/env bash
# Every query in this repo is executed against the real Open Dental schema before it ships.
# Builds a structure-only database from Open Dental's own published documentation XML,
# runs every .sql file against it, and fails if any one of them errors.
set -euo pipefail
VER="${OD_VERSION:-26-2}"
C=odq-verify
cleanup() { docker rm -f $C >/dev/null 2>&1 || true; }
trap cleanup EXIT

echo "==> fetching Open Dental $VER schema documentation"
curl -fsS "https://www.opendental.com/OpenDentalDocumentation${VER}.xml" -o /tmp/od-$VER.xml
python3 - "/tmp/od-$VER.xml" /tmp/od-$VER.sql <<'PY'
import xml.etree.ElementTree as ET, sys
r = ET.parse(sys.argv[1]).getroot(); out = []
for t in r.findall('table'):
    cols = ["  `%s` %s" % (c.get('name'), c.get('type')) for c in t.findall('column')]
    if cols:
        out.append("CREATE TABLE `%s` (\n%s\n);" % (t.get('name'), ",\n".join(cols)))
open(sys.argv[2], 'w').write("\n".join(out) + "\n")
print("   schema version %s: %d tables" % (r.get('version'), len(out)))
PY

echo "==> starting MariaDB"
cleanup
docker run -d --name $C -e MARIADB_ROOT_PASSWORD=od -e MARIADB_DATABASE=opendental mariadb:11 >/dev/null
for i in $(seq 1 45); do docker exec $C mariadb -uroot -pod -e "SELECT 1" >/dev/null 2>&1 && break; sleep 2; done
docker exec -i $C mariadb -uroot -pod opendental < /tmp/od-$VER.sql

echo "==> running every query"
fail=0
for f in queries/*.sql; do
  if docker exec -i $C mariadb -uroot -pod opendental < "$f" >/dev/null 2>/tmp/err; then
    echo "  PASS  $f"
  else
    echo "  FAIL  $f"; sed 's/^/        /' /tmp/err; fail=1
  fi
done
exit $fail
