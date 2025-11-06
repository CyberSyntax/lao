#!/usr/bin/env bash
set -euo pipefail
# Compile + run tests with sanitizers if a test runner is present.
# Enforce only when CI_SAN_ENFORCE=1 is set; otherwise skip quietly.

if [ -z "${CI_SAN_ENFORCE:-}" ]; then
  echo "Sanitizers: skipping (set CI_SAN_ENFORCE=1 to enforce)"; exit 0
fi

if command -v ctest >/dev/null 2>&1 && [ -d build ]; then
  echo "==> Running ctest with sanitizers (expect project to configure them)"
  ctest --output-on-failure || exit 1
else
  echo "No ctest/build found; skipping"; exit 0
fi
