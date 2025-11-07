#!/usr/bin/env bash
# vendor_integrations.sh — detect-only by default; enforce only with CI_VENDOR_ENFORCE=1
# Intentionally NOT using `set -e` or `pipefail`. We compute our own exit code
# so a missing tool never aborts the script in detect-only mode.
set -u

ENFORCE="${CI_VENDOR_ENFORCE:-0}"
printf 'vendor-integrations: ENFORCE=%s\n' "$ENFORCE"

VI_RC=0
chk() {
  local bin="$1" name="$2"
  if command -v "$bin" >/dev/null 2>&1; then
    printf 'found: %s (%s)\n' "$name" "$bin"
  else
    printf 'missing: %s (%s)\n' "$name" "$bin"
    if [ "$ENFORCE" = "1" ]; then VI_RC=1; fi
  fi
}

# Names vary by installation; adjust as needed for your environment.
chk "polyspace-code-prover" "Polyspace Code Prover"
chk "astr"                 "Astrée"
chk "codesonar"            "CodeSonar"
chk "cov-analyze"          "Coverity Static Analyzer"
chk "ldra"                 "LDRA"
chk "vcast"                "VectorCAST"
chk "sonar-scanner"        "SonarQube Scanner"
chk "structure101cli"      "Structure101"
chk "ccomp"                "CompCert (verified C compiler)"

exit "$VI_RC"
