# Public API guide

Theoria is still pre-1.0. This guide separates APIs intended for package users from experimental implementation surfaces.

## Stable-ish user APIs

These modules are intended for normal package usage and should evolve conservatively:

- `Theoria` — top-level constructors and environment helpers.
- `Theoria.Term`, `Theoria.Level`, `Theoria.Context`, `Theoria.Env` — core term/environment data structures.
- `Theoria.Kernel`, `Theoria.Normalize` — native trusted checking and normalization entrypoints.
- `Theoria.DSL`, `Theoria.Theorem`, `Theoria.Prelude` — theorem module workflow.
- `Theoria.Validation` — native validation workflows.
- `Theoria.Kernel.AssuranceSummary` — user-facing assurance summary.

## Experimental public APIs

These are useful but may change before 1.0:

- `Theoria.Equation` — equation compilation/realization facade.
- `Theoria.Rewrite`, `Theoria.Simp` — proof-producing rewrite/simp helpers.
- report structs under `Theoria.Kernel.*Report`.

Prefer documented facade functions and accessors instead of depending on internal struct layout.

## Internal and contributor APIs

These support generated artifacts, assurance, and contributor-only validation. They may change without compatibility shims before 1.0:

- `Theoria.Equation.Matcher.*`
- `Theoria.Equation.Matcher.Indexed.*`
- `Theoria.Equation.Schema.*`
- `Theoria.Kernel.Reference.*`
- `Theoria.Kernel.EnvironmentCorpus.*`
- `Theoria.Kernel.GeneratedTerm.*`
- `Theoria.Lean.*`

Lean modules are external oracle tooling, not part of the trusted runtime path.

## CLI workflows

User-facing CLI workflows:

```bash
mix theoria.theorems MyApp.Proofs
mix theoria.validate
mix theoria.kernel.check
mix theoria.kernel.check --assurance-summary
```

Experimental CLI workflows:

```bash
mix theoria.equations --realize nat_add
mix theoria.simp nat_add_zero --prove --explain
mix theoria.lean.check
```
