#!/usr/bin/env bash
# tool/inspect_configs.sh — curated by default; supports: curated|all|code|diff|wt|wt-all|wt-code
set -euo pipefail

usage() {
  cat <<'EOF'
usage: tool/inspect_configs.sh [curated|all|code|diff|wt|wt-all|wt-code]

  curated (default): policy/config/docs/tooling (tracked files)
  all              : every tracked file
  code             : tracked C/C++ code under src/, include/, tests/
  diff             : files changed vs HEAD (staged + unstaged)

  wt               : same as curated, but scans the worktree (not just tracked)
  wt-all           : list all files in the worktree (respects .gitignore)
  wt-code          : worktree C/C++ files under src/, include/, tests/

Tip: install 'bat' for pretty output. Otherwise we fall back to 'cat'.
EOF
}

mode="${1:-curated}"

HAVE_BAT=0; command -v bat >/dev/null 2>&1 && HAVE_BAT=1

show() {
  echo "================================"
  echo "File: $1"
  echo "================================"
  if [ "$HAVE_BAT" -eq 1 ]; then
    bat --style=header,grid --paging=never "$1"
  else
    cat "$1"
  fi
  echo
}

collect_git() {
  case "$1" in
    curated)
      git ls-files -- \
        ".pre-commit-config.yaml" \
        ".clang-tidy" \
        ".clang-format" \
        ".editorconfig" \
        ".gitattributes" \
        ".gitignore" \
        ".cz.toml" \
        "Makefile" \
        "rules/**/*.yaml" \
        "docs/**/*.md" \
        "tool/*.sh"
      ;;
    all)
      git ls-files
      ;;
    code)
      git ls-files -- \
        "src/**/*.c" "src/**/*.cc" "src/**/*.cpp" \
        "include/**/*.h" "include/**/*.hpp" \
        "tests/**/*.c" "tests/**/*.cc" "tests/**/*.cpp"
      ;;
    diff)
      git diff --name-only HEAD || true
      ;;
  esac
}

collect_worktree() {
  # mirrors your 'find' usage but portable; excludes .git and build
  find . -type f \
    -not -path '*/.git/*' \
    -not -path '*/build/*' \
    -not -name '.gitkeep' \
    -not -name '*.bin' \
    -not -name 'a.out' \
    -not -name '*.cmake' \
    -not -name '*.marks' \
    -not -name '*.json' \
    -not -name 'index' \
    "$@"
}

files_tmp="$(mktemp)"; trap 'rm -f "$files_tmp"' EXIT

case "$mode" in
  curated|all|code|diff)
    collect_git "$mode" >> "$files_tmp"
    ;;
  wt)
    collect_worktree -name ".pre-commit-config.yaml" -o -name ".clang-tidy" -o -name ".clang-format" -o -name ".editorconfig" -o -name ".gitattributes" -o -name ".gitignore" -o -name ".cz.toml" -o -name "Makefile" -o -path "./rules/*.yaml" -o -path "./rules/**/*.yaml" -o -path "./docs/*.md" -o -path "./docs/**/*.md" -o -path "./tool/*.sh" | sed 's|^\./||' >> "$files_tmp"
    ;;
  wt-all)
    collect_worktree | sed 's|^\./||' >> "$files_tmp"
    ;;
  wt-code)
    collect_worktree \( -path "./src/*.c" -o -path "./src/**/*.c" -o -path "./src/*.cc" -o -path "./src/**/*.cc" -o -path "./src/*.cpp" -o -path "./src/**/*.cpp" -o -path "./include/*.h" -o -path "./include/**/*.h" -o -path "./include/*.hpp" -o -path "./include/**/*.hpp" -o -path "./tests/*.c" -o -path "./tests/**/*.c" -o -path "./tests/*.cc" -o -path "./tests/**/*.cc" -o -path "./tests/*.cpp" -o -path "./tests/**/*.cpp" \) | sed 's|^\./||' >> "$files_tmp"
    ;;
  -h|--help|help)
    usage; exit 0 ;;
  *)
    echo "unknown mode: $mode"; usage; exit 2 ;;
esac

# De-dup, stable order
tmp="$(mktemp)"; trap 'rm -f "$tmp" "$files_tmp"' EXIT
awk 'NF && !seen[$0]++' "$files_tmp" | LC_ALL=C sort -u > "$tmp"

count=$(wc -l < "$tmp" | tr -d ' ')
if [ "$count" -eq 0 ]; then
  # If the git view was empty, fall back to a worktree curated scan automatically
  if [ "$mode" = "curated" ] || [ "$mode" = "all" ] || [ "$mode" = "code" ]; then
    echo "(info) No tracked files found for '$mode'. Falling back to worktree scan."
    exec "$0" wt
  fi
  echo "No files matched."
  exit 0
fi

while IFS= read -r f; do
  [ -f "$f" ] && show "$f"
done < "$tmp"
