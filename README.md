# LAO — Local Assurance Orchestra (Deepest‑Strict)

> **One command, reproducible quality gates.**
> **LAO** provides an ultra‑strict, verification‑friendly C/C++ environment with deterministic local gates. You run the same checks locally that CI runs—no surprises.

---

## Contents

- [Why this exists](#why-this-exists)
- [Quick start](#quick-start)
- [What the gates enforce](#what-the-gates-enforce)
  - [Micro (inside modules)](#micro-inside-modules)
  - [Macro (between modules)](#macro-between-modules)
  - [Determinism & purity](#determinism--purity)
- [Make targets](#make-targets)
- [Policies & configuration](#policies--configuration)
- [Developer workflow](#developer-workflow)
- [CI hardening toggles](#ci-hardening-toggles)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

---

## Why this exists

A tiny amount of upfront structural intent + continuous, automated guardrails leads to simpler, more analyzable software. **LAO** bakes in a **max‑strict** subset and **fitness functions** that:
- keep functions tiny and flat,
- prevent architecture drift (no forbidden edges or cycles),
- bias toward formal verification and abstract interpretation,
- and make “fix what the tools tell you” the default workflow.

See also: `docs/PHILOSOPHY.md`, `docs/MAX_STRICT.md`, and `docs/POLICY_INVARIANTS.md`.

---

## Quick start

```bash
# First time
chmod +x tool/*.sh
make git-init           # if not already a repo
make bootstrap          # installs tools, hooks, baseline; runs a full policy once

# Normal workflow
git add -p && git commit      # pre-commit runs staged-file checks
make policy                   # full repo: default + manual hook stages (will fail on issues)
```

macOS (Homebrew) tip:
```bash
echo 'export PATH="/opt/homebrew/opt/llvm/bin:$PATH"' >> ~/.zshrc
```

---

## What the gates enforce

The policy is intentionally tighter than common safety standards (Power‑of‑Ten, JPL, seL4, MISRA/AUTOSAR, JSF AV C++). Numbers below come from `rules/budgets.yaml`.

### Micro (inside modules)

- **Function budgets (hard):**
  lines ≤ **10**, nesting ≤ **1**, cyclomatic complexity ≤ **2**, parameters ≤ **2**, mutable locals ≤ **2**, duplication **0%**.
- **Static analysis (hard):** `clang-tidy` (diagnostics + CERT/HICPP/cppcoreguidelines) with **warnings as errors**, `cppcheck`, Semgrep packs (Power‑of‑Ten + local `max_strict.yaml`).
- **Language subset highlights (hard in `src/**`):**
  - **No** exceptions/RTTI/default args; **no** C‑style casts/`reinterpret_cast`/`const_cast`.
  - **No** recursion, `goto`, `switch`, `?:`, `for`/`do…while`, `break`/`continue`.
  - **No** pre/post `++/--`; **no** pointer arithmetic.
  - **No** macros/`#ifdef` in `src/**`; **no** unions; **no** inline asm.
  - **No** floating point in `src/**` (especially `src/core/**`).
  - Unsafe C APIs banned (`strcpy/scanf/sprintf/...`).

### Macro (between modules)

Architecture is declared in `rules/arch.yaml` and enforced by `tool/depgraph.sh`.

```
core  ←  domain  ←  ports  ←  adapters
allocator, concurrency (isolated)
```

- **No cycles**, and **no reverse edges** across modules.
- `src/core/**` cannot depend on `adapters/**` etc.
- Concurrency primitives live only in `src/concurrency/**`.

### Determinism & purity

- **`src/core/**` is pure:** **no I/O**, **no randomness/time**, **no sleeping**, **no heap after init**, **no global mutable state**.
- Dynamic allocation **only** during initialization via `src/allocator/**`.

---

## License

MIT License © 2025 CyberSyntax
See the [LICENSE](LICENSE) file in the repository root for full terms.

---
