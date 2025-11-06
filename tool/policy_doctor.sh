#!/usr/bin/env bash
set -euo pipefail

fail(){ echo "✗ $*" >&2; exit 1; }
ok(){ echo "✓ $*"; }

[ -f rules/arch.yaml ]         || fail "missing rules/arch.yaml"
[ -f rules/budgets.yaml ]      || fail "missing rules/budgets.yaml"
[ -f rules/semgrep/po10.yaml ] || fail "missing rules/semgrep/po10.yaml"
[ -f .pre-commit-config.yaml ] || fail "missing .pre-commit-config.yaml"
[ -f .clang-tidy ]             || fail "missing .clang-tidy"
[ -f .clang-format ]           || fail "missing .clang-format"
ok "policy files present"

grep -q 'id: policy-sync'   .pre-commit-config.yaml || fail "missing policy-sync hook"
grep -q 'id: policy-doctor' .pre-commit-config.yaml || fail "missing policy-doctor hook"
grep -q 'id: commitizen'    .pre-commit-config.yaml || fail "missing commit-message policy"
ok "policy hooks present"

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if git ls-files | grep -E '\.DS_Store$' >/dev/null; then
    fail ".DS_Store is tracked; run: git rm --cached -r .DS_Store **/.DS_Store"
  fi
  ok "no tracked .DS_Store files"
else
  echo "info: not a git repo; skipping tracked-file checks"
fi

missing=0
while read -r line; do
  root="${line#*roots: }"
  root="${root//[\[\]\",]/}"
  for p in $root; do
    p="${p%/**}"
    [ -d "$p" ] || { echo "missing directory for root: $p"; missing=1; }
  done
done < <(grep -n "roots:" rules/arch.yaml || true)
[ "$missing" -eq 0 ] || fail "some module roots do not exist"

# Ensure compile_commands.json is ignored
grep -q '^compile_commands\.json$' .gitignore || echo "WARN: add 'compile_commands.json' to .gitignore"

ok "policy doctor passed"
