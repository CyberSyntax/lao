#!/usr/bin/env bash
set -euo pipefail

if ! command -v valgrind >/dev/null 2>&1; then
  if [ -n "${CI_VALGRIND_ENFORCE:-}" ]; then
    echo "Valgrind missing and CI_VALGRIND_ENFORCE=1 set." >&2
    exit 1
  fi
  echo "Valgrind not found; skipping (set CI_VALGRIND_ENFORCE=1 to enforce)."
  exit 0
fi

TARGETS="${VALGRIND_TARGETS:-}"
if [ -z "$TARGETS" ]; then
  echo "Valgrind: no VALGRIND_TARGETS provided; skipping."
  exit 0
fi

rc=0
for t in $TARGETS; do
  if [ -x "$t" ]; then
    echo "==> Valgrind memcheck: $t"
    valgrind --error-exitcode=1 --leak-check=full --show-leak-kinds=all \
      "$t" >/dev/null 2>&1 || rc=1
  else
    echo "Valgrind target not executable: $t"
  fi
done
exit "$rc"
