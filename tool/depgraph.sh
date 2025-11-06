#!/usr/bin/env sh
set -eu

ARCH="rules/arch.yaml"
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
TMP="${TMPDIR:-/tmp}/dep.$$"
mkdir -p "$TMP"

# --- Build file->module map from arch.yaml (handles /** globs) ---
MAP="$TMP/map.txt"
awk '
  /name:/        {mod=$2}
  /roots:/       {getline; gsub(/[\[\],"]/,""); for(i=1;i<=NF;i++){if($i!="roots:"){print mod" " $i}}}
' "$ARCH" | sed 's#/\*\*$##' > "$MAP"

module_of() {
  f="$1"
  while read -r mod root; do
    case "$f" in
      "$root"|"${root}"/*) echo "$mod"; return 0 ;;
    esac
  done < "$MAP"
  echo "unknown"
}

# --- Collect include edges ---
EDGES="$TMP/edges.txt"; : > "$EDGES"

if [ -f compile_commands.json ] || [ -f build/compile_commands.json ]; then
  DB="compile_commands.json"
  [ -f build/compile_commands.json ] && DB="build/compile_commands.json"
  # Fallback to grep of includes inside files listed in the DB (portable)
  jq -r '.[].file' "$DB" 2>/dev/null | while read -r SRC; do
    [ -f "$SRC" ] || continue
    DIR=$(dirname "$SRC")
    grep -hE '^\s*#\s*include\s+"([^"]+)"' "$SRC" 2>/dev/null \
      | sed -E 's/.*"([^"]+)".*/\1/' \
      | while read -r H; do
          if   [ -f "$DIR/$H" ]; then DST="$DIR/$H"
          elif [ -f "$ROOT/include/$H" ]; then DST="$ROOT/include/$H"
          elif [ -f "$ROOT/$H" ]; then DST="$ROOT/$H"
          else DST=""; fi
          [ -n "$DST" ] && printf "%s -> %s\n" "$SRC" "$DST" >> "$EDGES"
        done
  done
else
  # Pure grep fallback over tracked sources/headers
  git ls-files '*.c' '*.cc' '*.cpp' '*.h' '*.hpp' | while read -r SRC; do
    DIR=$(dirname "$SRC")
    grep -hE '^\s*#\s*include\s+"([^"]+)"' "$SRC" 2>/dev/null \
      | sed -E 's/.*"([^"]+)".*/\1/' \
      | while read -r H; do
          if   [ -f "$DIR/$H" ]; then DST="$DIR/$H"
          elif [ -f "$ROOT/include/$H" ]; then DST="$ROOT/include/$H"
          elif [ -f "$ROOT/$H" ]; then DST="$ROOT/$H"
          else DST=""; fi
          [ -n "$DST" ] && printf "%s -> %s\n" "$SRC" "$DST" >> "$EDGES"
        done
  done
fi

# --- Module-level edges (skip unknowns and self-edges) ---
MOD_EDGES="$TMP/mod_edges.txt"; : > "$MOD_EDGES"
while read -r SRC _ DST; do
  [ -n "$SRC" ] || continue
  [ -n "$DST" ] || continue
  MSRC=$(module_of "$SRC")
  MDST=$(module_of "$DST")
  if [ "$MSRC" != "unknown" ] && [ "$MDST" != "unknown" ] && [ "$MSRC" != "$MDST" ]; then
    printf "%s -> %s\n" "$MSRC" "$MDST" >> "$MOD_EDGES"
  fi
done < "$EDGES"
sort -u "$MOD_EDGES" -o "$MOD_EDGES"

# --- Allowed edges from arch.yaml ---
ALLOW="$TMP/allow.txt"
awk '
  /name:/           {mod=$2}
  /may_depend_on:/  {getline; gsub(/[\[\],"]/,""); for(i=1;i<=NF;i++){if($i!="may_depend_on:"){print mod" -> " $i}}}
' "$ARCH" | sort -u > "$ALLOW"

viol=0

# --- Forbid reverse/unknown edges ---
while read -r E; do
  [ -z "$E" ] && continue
  grep -q -F "$E" "$ALLOW" || { echo "FORBIDDEN EDGE: $E"; viol=1; }
done < "$MOD_EDGES"

# --- Optional cycle detection using tsort (if available) ---
if command -v tsort >/dev/null 2>&1; then
  if ! awk '{print $1" "$3}' "$MOD_EDGES" | tsort >/dev/null 2>&1; then
    echo "CYCLE DETECTED in module graph"
    viol=1
  fi
fi

rm -rf "$TMP"
exit "$viol"
