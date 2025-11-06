# Policy Invariants (Non‑Negotiables)

1. **Pure core**: `src/core/**` has no I/O, no randomness or time, and no
   dynamic allocation after initialization.
2. **Single allocator facade**: Any dynamic allocation must be in
   `src/allocator/**` or through its interfaces.
3. **Dependency direction**: `core` ← `domain` ← `ports` ← `adapters`. The
   `adapters` module never depends on `core`.
4. **No cycles**: The module graph must be acyclic.
5. **Budgets**: function lines ≤ `function_lines_max`, CCN ≤ `cyclomatic_max`,
   duplication ≤ `duplication_percent_max`.
6. **No recursion, no goto, no variadic APIs** in safety‑critical paths.
7. **Deterministic RNG**: RNG and time access live behind a facade outside
   `src/core/**`.
8. **Reproducibility**: Tools are pinned and bootstrap is local‑first. Artifacts
   are not committed.
