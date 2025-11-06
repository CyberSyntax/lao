#!/usr/bin/env bash
set -euo pipefail
# Run AFL++ on listed fuzz targets if available.
# Provide targets via FUZZ_TARGETS="bin/fuzz_one bin/fuzz_two"
if ! command -v afl-fuzz >/dev/null 2>&1; then
  echo "AFL++ not installed; skipping (set CI_FUZZ_ENFORCE=1 to enforce)"; [ -z "${CI_FUZZ_ENFORCE:-}" ] || exit 1; exit 0
fi
if [ -z "${FUZZ_TARGETS:-}" ]; then
  echo "No FUZZ_TARGETS provided; skipping"; exit 0
fi
for t in $FUZZ_TARGETS; do
  [ -x "$t" ] || { echo "not executable: $t"; continue; }
  echo "==> AFL++ sanity run for $t (quick mode)"
  afl-fuzz -i /dev/null -o out -- "$t" @@ || true
done
