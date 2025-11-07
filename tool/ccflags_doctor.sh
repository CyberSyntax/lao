#!/usr/bin/env bash
set -euo pipefail

# Verify "dangerous features off" in compile_commands.json (if present).
# Enforce: no exceptions/RTTI, hardening warnings, strict aliasing off,
# default hidden visibility, and strong hygiene. GCC-only warnings are only
# required when the toolchain is GCC (not Clang/Apple Clang).

DB="compile_commands.json"
[ -f build/compile_commands.json ] && DB="build/compile_commands.json"
[ -f "$DB" ] || { echo "ccflags_doctor: no compile_commands.json; skip"; exit 0; }

# --- Detect toolchain from the first command in the DB (best-effort).
toolchain="unknown"
if grep -qi '"command": *".*clang' "$DB"; then
  toolchain="clang"
elif grep -qi '"command": *".*gcc' "$DB"; then
  toolchain="gcc"
fi
echo "ccflags_doctor: toolchain=${toolchain}"

# --- Common required flags (apply to both clang and gcc).
common_req_flags=(
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
  "-Wnull-dereference"
  "-Wdouble-promotion"
  "-Wvla"
  "-fstack-protector-strong"
  "-fno-omit-frame-pointer"
)

# GCC-only extras (not required for clang/Apple clang).
gcc_only_req_flags=(
  "-Wformat-overflow"
  "-Wformat-truncation"
)

missing=0
check_flag_present() {
  local flag="$1"
  if ! grep -q -- " $flag" "$DB"; then
    echo "ccflags_doctor: MISSING $flag"
    missing=1
  fi
}

# Check common flags
for f in "${common_req_flags[@]}"; do
  check_flag_present "$f"
done

# Check GCC-only flags only when toolchain is gcc
if [ "$toolchain" = "gcc" ]; then
  for f in "${gcc_only_req_flags[@]}"; do
    check_flag_present "$f"
  done
else
  # Informational message so users know why these aren't enforced on clang
  for f in "${gcc_only_req_flags[@]}"; do
    if ! grep -q -- " $f" "$DB"; then
      echo "ccflags_doctor: info (clang): $f not required"
    fi
  done
fi

# PIE/FORTIFY are platform-dependent; check loosely (advisory).
if ! grep -q -- " -fPIE" "$DB" && ! grep -q -- " -fpie" "$DB"; then
  echo "ccflags_doctor: MISSING -fPIE/-fpie (recommended)"
fi
if ! grep -q -- "-D_FORTIFY_SOURCE=3" "$DB" && ! grep -q -- "-D_FORTIFY_SOURCE=2" "$DB"; then
  echo "ccflags_doctor: MISSING -D_FORTIFY_SOURCE=2/3 (recommended)"
fi
if ! grep -q -- "-fstack-clash-protection" "$DB"; then
  echo "ccflags_doctor: MISSING -fstack-clash-protection (recommended if supported)"
fi

exit "$missing"
