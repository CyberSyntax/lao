#!/usr/bin/env sh
set -eu

POLICY="rules/budgets.yaml"

get() {
  awk -F: -v k="$1" '
    $1 ~ ("^"k"$") {
      v=$2
      sub(/#.*/, "", v); sub(/^[ \t]+/, "", v); sub(/[ \t]+$/, "", v)
      print v
    }
  ' "$POLICY" | tail -n1
}

LINES=$(get function_lines_max 2>/dev/null);    [ -n "$LINES" ] || LINES=16
NEST=$(get nesting_max 2>/dev/null);            [ -n "$NEST"  ] || NEST=1
CYCL=$(get cyclomatic_max 2>/dev/null);         [ -n "$CYCL"  ] || CYCL=4
DUP=$(get duplication_percent_max 2>/dev/null); [ -n "$DUP"   ] || DUP=0
ARGS=$(get params_max 2>/dev/null);             [ -n "$ARGS"  ] || ARGS=3

# Install lizard/jscpd if missing (best effort)
if ! command -v lizard >/dev/null 2>&1; then
  if command -v pipx >/dev/null 2>&1; then pipx install lizard >/dev/null 2>&1 || true
  else python3 -m pip install --user lizard >/dev/null 2>&1 || true
  fi
fi
if ! command -v jscpd >/dev/null 2>&1; then
  npm i -g jscpd@4 >/dev/null 2>&1 || true
fi

# CCN + length + args
# -C: CCN, -L: length (NLOC), -a: parameter count, -w: warnings
lizard -C "$CYCL" -L "$LINES" -a "$ARGS" -w src include || {
  echo "Budget violation (CCN>${CYCL} or lines>${LINES} or params>${ARGS})"
  exit 1
}

# Duplication
jscpd --min-tokens 50 --threshold "$DUP" src include || {
  echo "Duplication > ${DUP}%"
  exit 1
}
