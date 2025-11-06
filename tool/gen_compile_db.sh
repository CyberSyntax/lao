#!/usr/bin/env sh
set -eu

if [ -f "compile_commands.json" ]; then
  echo "compile_commands.json already exists"
  exit 0
fi

if [ -f "CMakeLists.txt" ] && command -v cmake >/dev/null 2>&1; then
  cmake -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON >/dev/null
  cp -f build/compile_commands.json ./compile_commands.json
  echo "Generated compile_commands.json via CMake"
  exit 0
fi

if command -v bear >/dev/null 2>&1; then
  if [ -f "Makefile" ] || [ -f "makefile" ]; then
    bear -- make -j >/dev/null || true
    [ -f "compile_commands.json" ] && { echo "Generated via bear+make"; exit 0; }
  fi
fi

echo "WARN: Could not generate compile_commands.json (no CMake/bear). clang-tidy will fall back to -Iinclude."
exit 0
