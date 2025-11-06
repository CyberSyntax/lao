# Getting Started — Local Assurance Orchestra (Deepest‑Strict)

This repo is wired for local, deterministic quality gates. One command gives
meaningful feedback, and the same gates run on every commit.

---

## First run

```bash
chmod +x tool/*.sh
make git-init
make bootstrap
# then during normal work:
git add -p && git commit      # staged-file checks
make policy                   # full-repo check on demand
```

---

## What each gate enforces

### Micro (inside modules)

* `clang-tidy`: CERT + budgets. `.clang-tidy` is synced from
  `rules/budgets.yaml`. All warnings are treated as errors.
* `Semgrep`: Power of Ten and hard boundaries. No I/O, rand, time, sleep, or
  VLA in `src/core/**`. No heap after init outside `src/allocator/**`.
* `lizard`: CCN ≤ `rules/budgets.yaml:cyclomatic_max`.
* `jscpd`: duplication ≤ `rules/budgets.yaml:duplication_percent_max`.

### Macro (between modules)

* `rules/arch.yaml` defines module roots and allowed `may_depend_on`.
* `tool/depgraph.sh` rejects forbidden edges and any cycle.

### Determinism

* `src/core/**` is pure: no I/O, no randomness or time, and no heap after init.
* Side effects live in `src/adapters/**`. Interfaces live in `src/ports/**`.

---

## Local vs CI enforcement

**Local default (strict, reproducible):**

* Run `make policy`. All open‑source analyzers are enforced.
* Commercial analyzers are **detect‑only**; the vendor hook prints what’s
  installed but **does not fail** locally.

**CI hardening (when licenses are available):**

* Set `CI_VENDOR_ENFORCE=1` in the CI job environment to **fail** if a listed
  vendor tool is missing.
* Optional gates with their toggles:

  * Formal tools: `CI_FORMAL_ENFORCE=1`
  * Sanitizers via ctest: `CI_SAN_ENFORCE=1`
  * MC/DC placeholder: `CI_MCDC_ENFORCE=1`
  * Valgrind: `CI_VALGRIND_ENFORCE=1`

---

## Useful commands

```bash
make policy     # run everything (default + manual stages)
make depgraph   # architecture-only gate
make sync       # sync .clang-tidy from budgets (also enforced by a hook)
make doctor     # structural invariants
make autoupdate # refresh hook versions, then review diffs
make secrets    # regenerate .secrets.baseline
```

---

## macOS and Homebrew

LLVM is keg‑only. If you need it at the front of PATH:

```bash
echo 'export PATH="/opt/homebrew/opt/llvm/bin:$PATH"' >> ~/.zshrc
```

Python CLIs use `pipx` to avoid PEP‑668 issues.

---

## Philosophy

A tiny amount of upfront structural intent plus continuous, automated
guardrails. Fix what the tools tell you. Fitness functions protect the
macro‑architecture.

* Pure `src/core/**`.
* One allocator facade.
* Explicit dependencies. No cycles.
* Budgets ratcheted down over time.
