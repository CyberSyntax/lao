#!/usr/bin/env bash
set -euo pipefail

# Verify "dangerous features off" in compile_commands.json (if present)
# Enforce: no exceptions/RTTI, hardening warnings, strict aliasing off, visibility default-hidden.

DB="compile_commands.json"
[ -f build/compile_commands.json ] && DB="build/compile_commands.json"
[ -f "$DB" ] || { echo "ccflags_doctor: no compile_commands.json; skip"; exit 0; }

req_flags=(
  "-fno-exceptions"
  "-fno-rtti"
  "-fno-strict-aliasing"
  "-fvisibility=hidden"
  "-Wall"
  "-Wextra"
  "-Werror"
  "-Wconversion"
  "-Wsign-conversion"
  "-Wshadow"
  "-Wpedantic"
  "-Wformat"
  "-Wformat-security"
  "-Wvla"
  "-fstack-protector-strong"
  "-fno-omit-frame-pointer"
)

missing=0
for f in "${req_flags[@]}"; do
  if ! grep -q -- " $f" "$DB"; then
    echo "ccflags_doctor: MISSING $f"
    missing=1
  fi
done

# PIE/FORTIFY are platform-dependent; check loosely
if ! grep -q -- " -fPIE" "$DB" && ! grep -q -- " -fpie" "$DB"; then
  echo "ccflags_doctor: MISSING -fPIE/-fpie (recommended)"
fi
if ! grep -q -- "-D_FORTIFY_SOURCE=3" "$DB" && ! grep -q -- "-D_FORTIFY_SOURCE=2" "$DB"; then
  echo "ccflags_doctor: MISSING -D_FORTIFY_SOURCE=2/3 (recommended)"
fi

exit "$missing"
