#!/usr/bin/env bash
set -euo pipefail

# Enforce only in CI when explicitly requested
ENFORCE="${CI_FORMAL_ENFORCE:-}"
RC=0

say(){ printf "\033[1;36m%s\033[0m\n" "$*"; }
warn(){ printf "\033[1;33m%s\033[0m\n" "$*"; }

FILES=$(git ls-files 'src/**/*.c' 'src/core/**/*.c' 2>/dev/null || true)

if [ -z "$FILES" ]; then
  say "No C files found for formal verification."
  exit 0
fi

HAVE_FRAMA=0; command -v frama-c >/dev/null 2>&1 && HAVE_FRAMA=1
HAVE_CBMC=0;  command -v cbmc >/dev/null 2>&1 && HAVE_CBMC=1
HAVE_ESBMC=0; command -v esbmc >/dev/null 2>&1 && HAVE_ESBMC=1

if [ "$HAVE_FRAMA" -eq 0 ] && [ "$HAVE_CBMC" -eq 0 ] && [ "$HAVE_ESBMC" -eq 0 ]; then
  if [ -n "$ENFORCE" ]; then
    echo "Formal tools missing but CI_FORMAL_ENFORCE set." >&2
    exit 1
  fi
  warn "Frama-C/CBMC/ESBMC not found; skipping (set CI_FORMAL_ENFORCE=1 to enforce)"
  exit 0
fi

if [ "$HAVE_FRAMA" -eq 1 ]; then
  say "==> Frama-C WP on core (best effort, 10s timeout each)"
  for f in $FILES; do
    frama-c -warn-special -wp -wp-timeout 10 "$f" >/dev/null 2>&1 || RC=1
  done
fi

if [ "$HAVE_CBMC" -eq 1 ]; then
  say "==> CBMC safety checks (bounds/pointer/overflow) (best effort)"
  for f in $FILES; do
    cbmc --bounds-check --pointer-check --signed-overflow-check --unsigned-overflow-check \
        --nan-check --div-by-zero-check "$f" >/dev/null 2>&1 || RC=1
  done
fi

if [ "$HAVE_ESBMC" -eq 1 ]; then
  say "==> ESBMC safety checks (quick mode) (best effort)"
  for f in $FILES; do
    esbmc --no-bounds-check --no-pointer-check "$f" >/dev/null 2>&1 || RC=1
  done
fi

exit "$RC"
