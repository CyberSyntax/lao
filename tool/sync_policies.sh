#!/usr/bin/env bash
set -euo pipefail

POLICY="rules/budgets.yaml"
OUT=".clang-tidy"
TMP="$(mktemp)"

get() {
  awk -F: -v k="$1" '
    $1 ~ ("^"k"$") {
      v=$2
      sub(/#.*/, "", v)
      sub(/^[ \t]+/, "", v)
      sub(/[ \t]+$/, "", v)
      print v
    }
  ' "$POLICY" | tail -n1
}

lines="$(get function_lines_max || echo 40)"
nest="$(get nesting_max || echo 3)"
stmts="$(get statement_threshold || echo 50)"
branch="$(get branch_threshold || echo 8)"

cat > "$TMP" <<EOF
Checks: >
  clang-diagnostic-*,
  clang-analyzer-*,
  bugprone-*,
  performance-*,
  portability-*,
  readability-*,
  modernize-*,
  cppcoreguidelines-*,
  hicpp-*,
  cert-*,
  misc-no-recursion
WarningsAsErrors: '*'
HeaderFilterRegex: '^(src|include)/'
FormatStyle: file
CheckOptions:
  - { key: readability-function-size.LineThreshold,      value: ${lines} }
  - { key: readability-function-size.NestingThreshold,   value: ${nest} }
  - { key: readability-function-size.StatementThreshold, value: ${stmts} }
  - { key: readability-function-size.BranchThreshold,    value: ${branch} }
  - { key: readability-identifier-naming.FunctionCase,   value: lower_case }
  - { key: readability-identifier-naming.VariableCase,   value: lower_case }
EOF

mode="${1:-write}"
if [[ "$mode" == "--check" ]]; then
  if ! diff -u "$TMP" "$OUT" >/dev/null 2>&1; then
    echo ".clang-tidy is out of sync with rules/budgets.yaml (run: tool/sync_policies.sh)"
    diff -u "$OUT" "$TMP" || true
    rm -f "$TMP"
    exit 1
  fi
  rm -f "$TMP"
  exit 0
fi

mv "$TMP" "$OUT"
echo "Synced $OUT from $POLICY"
