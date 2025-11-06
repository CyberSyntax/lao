# Perfect Max‑Strict Baseline

This document captures the **strictest** profile used in this repo. It is
designed for predictability, testability, and verifiability.

## Budgets

- Function lines: **≤ 16**
- Nesting depth: **≤ 1**
- Cyclomatic complexity: **≤ 4**
- Parameters per function: **≤ 3**
- Local non‑const vars per function: **≤ 4**
- Duplication: **0%**

## Forbidden

- Control flow: `goto`, recursion, `for`, `do { } while`, `switch/case`, `?:`
- Arrays: variable length arrays (VLA)
- Macros: function‑like macros; dangerous `#pragma`
- C++: exceptions, RTTI, `using namespace std;`, C‑style/`reinterpret_cast`/`const_cast`
- Pointer arithmetic increments (`++`, `--`, `+=`, `-=`) on pointers
- Inline assembly
- Unsafe C APIs: `gets/strcpy/strcat/sprintf/vsprintf/scanf` family

## Purity and determinism

- `src/core/**`: no I/O, no sleep, no time/rand, no direct syscalls, no float,
  no dynamic allocation after initialization, no global mutable state.
- Concurrency primitives only in `src/concurrency/**`.
- Allocation only via `src/allocator/**`.

## Tooling

- Static: clang‑tidy (CERT/HICPP/cppcoreguidelines), cppcheck, Semgrep
  (Power‑of‑Ten + max_strict).
- Budgets: lizard (CCN/length/args), jscpd (duplication).
- Architecture: depgraph (no cycles / reverse edges).
- Optional in CI: Frama‑C WP, CBMC/ESBMC, sanitizers via ctest, AFL++ fuzz,
  Valgrind memcheck, MC/DC gate, **vendor integrations**.

### Enforcement modes

- **Local developer runs:** commercial vendor integrations are detect‑only and
  do not fail the build.
- **CI (licensed environments):** set `CI_VENDOR_ENFORCE=1` to require vendor
  tools; the pipeline fails if any are missing.
