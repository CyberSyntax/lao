# Perfect Max‑Strict Baseline

This document captures the **strictest** profile used in this repo. It is
designed for predictability, testability, verifiability, and
certification‑readiness.

## Budgets

- Function lines: **≤ 10**
- Nesting depth: **≤ 1**
- Cyclomatic complexity: **≤ 2**
- Parameters per function: **≤ 2**
- Local non‑const vars per function: **≤ 2**
- Duplication: **0%**

## Forbidden

- Control flow: `goto`, recursion, `for`, `do { } while`, `switch/case`, `?:`,
  **pre/post `++`/`--`**
- Arrays: variable length arrays (VLA)
- Macros: function‑like macros; dangerous `#pragma`
- Preprocessor: **no `##` token pasting, no `#undef`, no local `#define`**
- C++: exceptions, RTTI, `using namespace std;`,
  C‑style/`reinterpret_cast`/`const_cast`
- Pointer arithmetic increments (`++`, `--`, `+=`, `-=`) on pointers
- Inline assembly
- Unsafe C APIs: `gets/strcpy/strcat/sprintf/vsprintf/scanf` family;
  **no `setjmp/longjmp`**

## Purity and determinism

- `src/core/**`: no I/O, no sleep, no time/rand, no direct syscalls,
  no dynamic allocation after initialization, no global mutable state.
- `src/**`: **no floating point**, **no `restrict`**, no `union`.
- Concurrency primitives only in `src/concurrency/**`.
- Allocation only via `src/allocator/**`.

## Tooling

- Static: clang‑tidy (CERT/HICPP/cppcoreguidelines), cppcheck, Semgrep
  (Power‑of‑Ten + max_strict).
- Budgets: lizard (CCN/length/args), jscpd (duplication).
- Architecture: depgraph (no cycles / reverse edges).
- Optional in CI (enforce with env flags): Frama‑C (EVA/WP), CBMC/ESBMC,
  sanitizers via `ctest`, AFL++ fuzz, Valgrind memcheck, MC/DC gate,
  **CompCert clean compile**, vendor integrations
  (Polyspace/Astrée/CodeSonar/Coverity/LDRA/VectorCAST/SonarQube/Structure101).

### Enforcement modes

- **Local developer runs:** commercial vendor integrations are detect‑only and
  do not fail the build.
- **CI (licensed environments):** set `CI_VENDOR_ENFORCE=1` to require vendor
  tools; the pipeline fails if any are missing.
  - `CI_VC_ENFORCE=1` — require CompCert clean build
  - `CI_FORMAL_ENFORCE=1`, `CI_SAN_ENFORCE=1`, `CI_MCDC_ENFORCE=1`,
    `CI_VALGRIND_ENFORCE=1`
