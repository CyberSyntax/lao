#!/usr/bin/env bash
set -euo pipefail
# MC/DC gate: prefer vendor reports (VectorCAST/LDRA/RapiTest/Coco/CTC++).
# If none present, fall back to branch coverage floor with explicit "MC/DC unavailable".

ENFORCE="${CI_MCDC_ENFORCE:-}"

VC_REPORT="${VECTORCAST_REPORT:-build/coverage/vectorcast_mcdc.txt}"
LDRA_REPORT="${LDRA_REPORT:-build/coverage/ldra_mcdc.txt}"
RPT_REPORT="${RAPITEST_REPORT:-build/coverage/rapitest_mcdc.txt}"
COCO_REPORT="${COCO_REPORT:-build/coverage/coco_mcdc.txt}"
CTC_REPORT="${CTC_REPORT:-build/coverage/ctc_mcdc.txt}"
GENERIC="${MCDC_REPORT:-build/coverage/mcdc.txt}"
BRANCH_XML="${BRANCH_COVERAGE_XML:-build/coverage/coverage.xml}"
THRESH="${MCDC_MIN:-100}"

read_pct() { awk '/MC\/DC|MCDC|MC-DC/ {gsub(/[^0-9]/," ",$0); for(i=1;i<=NF;i++) if($i+0>0 && $i+0<=100) last=$i; } END{print (last+0)}' "$1" 2>/dev/null || true; }
pick_report() {
  for r in "$VC_REPORT" "$LDRA_REPORT" "$RPT_REPORT" "$COCO_REPORT" "$CTC_REPORT" "$GENERIC"; do
    [ -f "$r" ] && { echo "$r"; return; }
  done
  echo ""
}

RPT="$(pick_report)"
if [ -n "$RPT" ]; then
  PCT="$(read_pct "$RPT")"
  echo "MC/DC report: $RPT -> ${PCT}% (min ${THRESH}%)"
  if [ -n "$ENFORCE" ] && [ "${PCT:-0}" -lt "$THRESH" ]; then exit 1; fi
  exit 0
fi

echo "MC/DC: no vendor report found."
if [ -n "$BRANCH_XML" ] && [ -f "$BRANCH_XML" ]; then
  echo "Falling back to branch coverage floor (MC/DC unavailable)."
  FLOOR="${BRANCH_FLOOR:-95}"
  BPCT=$(awk -F'"' '/branch-rate=/{for(i=1;i<=NF;i++) if($i ~ /branch-rate=/){gsub(/branch-rate=/,"",$i); print int($i*100+0.5); exit}}' "$BRANCH_XML" || echo 0)
  echo "Branch coverage: ${BPCT}% (floor ${FLOOR}%)"
  if [ -n "$ENFORCE" ] && [ "${BPCT:-0}" -lt "$FLOOR" ]; then exit 1; fi
  exit 0
fi

if [ -n "$ENFORCE" ]; then
  echo "MC/DC ENFORCED but unavailable — failing."; exit 1
fi
echo "MC/DC not enforced and unavailable — skipping."
exit 0
