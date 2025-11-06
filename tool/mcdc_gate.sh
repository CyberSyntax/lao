#!/usr/bin/env bash
set -euo pipefail
# Approx/placeholder MC/DC gate.
# True MC/DC typically requires commercial tooling (VectorCAST/LDRA).
# If CI_MCDC_ENFORCE=1, fail unless MC/DC report is found and passes a threshold.

if [ -z "${CI_MCDC_ENFORCE:-}" ]; then
  echo "MC/DC: skipping (set CI_MCDC_ENFORCE=1 to enforce and provide reports)"; exit 0
fi

REPORT="${MCDC_REPORT:-build/coverage/mcdc.txt}"
THRESH="${MCDC_MIN:-100}" # default: require full MC/DC
if [ ! -f "$REPORT" ]; then
  echo "MC/DC report missing: $REPORT"; exit 1
fi

PCT=$(awk '/MC\/DC/ {print $NF+0}' "$REPORT" 2>/dev/null || echo 0)
echo "MC/DC coverage: $PCT% (min $THRESH%)"
[ "$PCT" -ge "$THRESH" ] || exit 1
