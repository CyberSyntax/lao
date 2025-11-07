# Perfect Max-Strict Baseline (v1)

**Goal:** a tiny, verifiable C/C++ subset and automated gates that are tighter
than typical spacecraft code and bias toward formal proof and abstract
interpretation. This consolidates the strictest constraints from: NASA/JPL
Power-of-Ten and JPL C Standard (no recursion; bounded loops; no dynamic
allocation after init), JSF Air Vehicle C++ (no exceptions/RTTI/default args),
seL4 (verification-friendly subset), MISRA C and AUTOSAR C++14 (ban dynamic
allocation in safety code), and CERT C/C++ (unsafe APIs, I/O, and exception
hygiene).

---

## Quantitative budgets (local hard gates)

| Budget                 | Value |
|------------------------|-------|
| Function lines         | ≤ 10  |
| Nesting                | ≤ 1   |
| Cyclomatic Complexity  | ≤ 2   |
| Params per function    | ≤ 2   |
| Local (non-const) vars | ≤ 2   |
| Duplication            | 0%    |
| (Advisory) loops/func  | ≤ 1, bounded |
| (Advisory) returns     | 1     |

---

## Language subset (forbidden or restricted)

- **Control flow:** no `goto`, recursion, `for`, `do { } while`, `switch/case`,
  ternary `?:`, and no `break`/`continue` (structured, single-exit loops).
- **Macros & preprocessor in `src/**`:** no `#define`, no `#undef`, no token
  pasting `##`, and no `#ifdef/#ifndef`; use constants, enums, or inline /
  `constexpr`.
- **C++ features:** no exceptions, no RTTI, no default args, no
  `using namespace std;`, no `dynamic_cast`, no `const_cast`/`reinterpret_cast`,
  and no C-style casts.
- **Pointers & arithmetic:** no pre/post `++/--` anywhere; no pointer
  increments/`+=`/`-=` (proof-friendly).
- **Types & numerics:** no `union`; **no floating point anywhere in `src/**`**;
  no `restrict`.
- **APIs:** ban unsafe C APIs (`gets/strcpy/strcat/sprintf/vsprintf/scanf`
  family) and `setjmp/longjmp`.
- **Inline asm & pragmas:** forbidden.
- **Asserts in prod:** no `assert()` in `src/**` (tests only).

---

## Purity, determinism, and boundaries

- **Core purity (`src/core/**`)**: no I/O, no sleep, no time/rand, no direct
  syscalls, no dynamic allocation after initialization, and no global mutable
  state.
- **Memory**: dynamic allocation only via `src/allocator/**`, and never after
  initialization.
- **Concurrency**: primitives only in `src/concurrency/**`.

---

## Tooling & enforcement

- **Static & structure:** clang-tidy (diagnostics + CERT/HICPP/cppcoreguidelines),
  Semgrep packs (Po10/boundaries/max_strict + CWE Top-25), cppcheck; budgets via
  lizard & jscpd; architecture via depgraph.
- **Dynamic & coverage:** sanitizers (ASan/UBSan/TSan), Valgrind memcheck, AFL++
  fuzz, MC/DC (prefer vendor reports; branch-coverage fallback when MC/DC is
  unavailable).
- **Formal & verified:** Frama-C EVA/WP, CBMC/ESBMC; CompCert clean compile (if
  available) for verified semantics.

### Enforcement modes

- **Local:** vendor tools are detect-only; everything else enforced.
- **CI:** set `CI_VENDOR_ENFORCE=1` (require vendor tools). Also available:
  `CI_VC_ENFORCE=1`, `CI_FORMAL_ENFORCE=1`, `CI_SAN_ENFORCE=1`,
  `CI_MCDC_ENFORCE=1`, `CI_VALGRIND_ENFORCE=1`.

---

## Practical guidance

- Keep functions tiny and flat; refactor early.
- Prefer fixed-width integers and explicit conversions.
- Keep `src/core/**` pure; wire side-effects in `src/adapters/**`.
- Budget violations are design signals—split responsibilities, isolate effects,
  and move calculations to pure helpers where possible.
