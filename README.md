# LAO — Local Assurance Orchestra (Deepest-Strict)

**One command, reproducible quality gates.**
LAO provides an ultra-strict, verification-friendly C/C++ environment with
deterministic local gates. You run the same checks locally that CI runs.

---

## Contents

- [Why this exists](#why-this-exists)
- [Quick start](#quick-start)
- [What the gates enforce](#what-the-gates-enforce)
  - [Micro (inside modules)](#micro-inside-modules)
  - [Macro (between modules)](#macro-between-modules)
  - [Determinism and purity](#determinism-and-purity)
- [Project layout](#project-layout)
- [Make targets](#make-targets)
- [Policies and configuration](#policies-and-configuration)
- [Developer workflow](#developer-workflow)
- [CI hardening toggles](#ci-hardening-toggles)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

---

## Why this exists

A small amount of structural intent plus continuous, automated guardrails
produces simpler and more analyzable software. LAO bakes in a max-strict
subset and fitness functions that:

- keep functions tiny and flat,
- prevent architecture drift (no forbidden edges or cycles),
- bias toward formal verification and abstract interpretation, and
- make “fix what the tools tell you” the default workflow.

See also: `docs/PHILOSOPHY.md`, `docs/MAX_STRICT.md`,
and `docs/POLICY_INVARIANTS.md`.

---

## Quick start

```bash
# First time
chmod +x tool/*.sh
make git-init
make bootstrap        # installs tools and runs a full policy once

# Normal workflow
git add -p && git commit        # staged-file checks
make policy                     # full repo (fails on issues)
```

On macOS (Homebrew), place LLVM on the PATH:

```bash
echo 'export PATH="/opt/homebrew/opt/llvm/bin:$PATH"' >> ~/.zshrc
```

---

## What the gates enforce

The policy is tighter than common safety standards (Power-of-Ten, JPL, seL4,
MISRA/AUTOSAR, JSF AV C++). Numbers come from `rules/budgets.yaml`.

### Micro (inside modules)

- **Function budgets (hard):** lines ≤ 10, nesting ≤ 1, cyclomatic ≤ 2,
  params ≤ 2, mutable locals ≤ 2, duplication 0%.
- **Static analysis (hard):** `clang-tidy` (diagnostics + CERT/HICPP/
  cppcoreguidelines) with warnings as errors, `cppcheck`, and Semgrep packs
  (Power-of-Ten + local `max_strict.yaml`).
- **Language subset (hard in `src/**`):**
  - No exceptions/RTTI/default args. No C-style casts, `reinterpret_cast`,
    or `const_cast`.
  - No recursion, `goto`, `switch`, `?:`, `for`/`do…while`, `break`/
    `continue`.
  - No pre/post `++/--`. No pointer arithmetic.
  - No macros or `#ifdef` in `src/**`. No unions. No inline asm.
  - No floating point in `src/**` (especially `src/core/**`).
  - Unsafe C APIs banned (`strcpy`, `scanf`, `sprintf`, etc.).

### Macro (between modules)

Architecture is declared in `rules/arch.yaml` and enforced by `tool/depgraph.sh`.

```text
core  ←  domain  ←  ports  ←  adapters
allocator, concurrency (isolated)
```

- No cycles and no reverse edges across modules.
- `src/core/**` cannot depend on `adapters/**` and similar.
- Concurrency primitives live only in `src/concurrency/**`.

### Determinism and purity

- `src/core/**` is pure: no I/O, no randomness or time, no sleeping,
  no heap after init, and no global mutable state.
- Dynamic allocation is allowed only during initialization via
  `src/allocator/**`.

---

## Project layout

A typical project mirrors the modules above. See the root docs for examples
and the full policy.

---

## Make targets

```make
make policy           # full repo (default + manual stages)
make policy-report    # non-blocking summary
make bootstrap        # install/pin tools and run a first policy
make ccdb             # generate compile_commands.json (best-effort)
```

---

## Policies and configuration

- Numbers live in `rules/budgets.yaml`.
- Architecture lives in `rules/arch.yaml`.
- Semgrep rule packs live in `rules/semgrep/**`.

---

## Developer workflow

1. Edit in small steps.
2. Run `make policy-report` for a fast, non-blocking pass.
3. Before pushing, run `make policy` and fix all findings.
4. Commit only after the tree is clean.

---

## CI hardening toggles

Set these environment variables in CI to enforce optional vendor tools:

- `CI_VENDOR_ENFORCE=1` (require vendor analyzers if listed),
- `CI_FORMAL_ENFORCE=1` (formal proof hooks),
- `CI_SAN_ENFORCE=1` (sanitizers via ctest),
- `CI_MCDC_ENFORCE=1` (MC/DC vendor reports),
- `CI_VALGRIND_ENFORCE=1` (memcheck).

---

## Troubleshooting

- **Missing submodules.** Run
  `git submodule update --init --recursive`.
- **clang-tidy cannot find a compile DB.** Run `make ccdb`.
- **Toolchain errors.** Confirm LLVM on PATH and re-run `make bootstrap`.

---

## Contributing

Keep code small and pure, follow the budgets, and let the gates guide fixes.
Do not relax rules. If a tool needs a deterministic input (for example a
compile DB), add that input under version control.

---

## License

MIT License © 2025 CyberSyntax. See `LICENSE` in the repository root.
