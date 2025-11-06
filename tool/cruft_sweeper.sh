#!/usr/bin/env bash
# tool/cruft_sweeper.sh
set -euo pipefail

usage() {
  cat <<'EOF'
cruft_sweeper.sh --preview | --delete | --untrack | --sweep

  --preview : show OS cruft to delete and tracked-ignored files to untrack
  --delete  : delete local OS cruft (.DS_Store, Thumbs.db, Desktop.ini, ._*)
  --untrack : git rm --cached any files that are ignored by .gitignore but tracked
  --sweep   : run --untrack then --delete

Notes:
- We do NOT call `git clean -fdX` to avoid removing useful ignored files like compile_commands.json.
- Safe to run inside pre-commit; it only stages untracks, no commits.
EOF
}

in_git_repo() { git rev-parse --is-inside-work-tree >/dev/null 2>&1; }

# NUL-delimited sets
list_tracked_ignored_nul() { git ls-files -ci --exclude-standard -z; }
list_os_cruft_untracked_nul() {
  find . -type f -not -path '*/.git/*' \
    \( -name '.DS_Store' -o -name 'Thumbs.db' -o -name 'Desktop.ini' -o -name 'ehthumbs.db' -o -name '._*' \) \
    -print0 2>/dev/null || true
}
# precise match for legacy Finder "Icon<CR>"
list_icon_cr_nul() {
  find . -type f -not -path '*/.git/*' -name 'Icon?' -print0 2>/dev/null \
    | while IFS= read -r -d '' f; do
        base="$(basename "$f")"
        case "$base" in $'Icon\r') printf '%s\0' "$f" ;; esac
      done
}

do_preview() {
  echo "==> Tracked-but-ignored (will be untracked):"
  if in_git_repo; then
    if [ -n "$(git ls-files -ci --exclude-standard | head -n 1)" ]; then
      git ls-files -ci --exclude-standard | sed 's/^/  /'
    fi
  else
    echo "  (not a git repo)"
  fi
  echo
  echo "==> Untracked OS cruft (will be deleted):"
  { list_os_cruft_untracked_nul; list_icon_cr_nul; } | tr '\0' '\n' | sed 's/^/  /' || true
}

do_untrack() {
  in_git_repo || { echo "Not a git repo"; exit 1; }
  cnt="$(list_tracked_ignored_nul | tr -cd '\000' | wc -c | tr -d ' ')"
  if [ "$cnt" -gt 0 ]; then
    list_tracked_ignored_nul | xargs -0 git rm -r --cached --ignore-unmatch -- >/dev/null 2>&1 || true
    echo "Untracked $cnt tracked-ignored file(s). They will disappear from Git on this commit."
  else
    echo "No tracked-ignored files to untrack."
  fi
}

do_delete() {
  c1="$(list_os_cruft_untracked_nul | tr -cd '\000' | wc -c | tr -d ' ')"
  c2="$(list_icon_cr_nul           | tr -cd '\000' | wc -c | tr -d ' ')"
  total=$((c1 + c2))
  if [ "$total" -gt 0 ]; then
    list_os_cruft_untracked_nul | xargs -0 rm -f -- 2>/dev/null || true
    list_icon_cr_nul           | xargs -0 rm -f -- 2>/dev/null || true
    echo "Deleted $total OS cruft file(s) from working tree."
  else
    echo "No OS cruft found to delete."
  fi
}

case "${1:-}" in
  --preview) do_preview ;;
  --delete)  do_delete ;;
  --untrack) do_untrack ;;
  --sweep)   do_untrack; echo; do_delete ;;
  -h|--help|"") usage; exit 0 ;;
  *) echo "Unknown mode: $1"; usage; exit 2 ;;
esac
