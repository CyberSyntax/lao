#!/usr/bin/env bash
set -euo pipefail
# Compile C sources with CompCert C (ccomp) if available.
# Detect-only locally; enforce in CI with CI_VC_ENFORCE=1.
ENFORCE="${CI_VC_ENFORCE:-}"

if ! command -v ccomp >/dev/null 2>&1; then
  echo "CompCert (ccomp) not found; skipping (set CI_VC_ENFORCE=1 to enforce)."
  [ -z "$ENFORCE" ] || exit 1
  exit 0
fi

SRC=$(git ls-files 'src/**/*.c' 'include/**/*.h' 2>/dev/null | tr '\n' ' ')
[ -n "$SRC" ] || { echo "verified-compiler: no C files"; exit 0; }

TMPDIR="${TMPDIR:-/tmp}/ccomp.$$"
mkdir -p "$TMPDIR"
RC=0

echo "==> CompCert check (syntax + type + UB-prone constructs)"
for c in $(git ls-files 'src/**/*.c'); do
  # -Wall equivalent in CompCert is limited; rely on ccomp diagnostics.
  if ! ccomp -quiet -c "$c" -o "$TMPDIR/$(basename "$c").o" >/dev/null 2>&1; then
    echo "ccomp failed on: $c"
    RC=1
  fi
done

rm -rf "$TMPDIR"
exit "$RC"
