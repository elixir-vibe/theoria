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
- `Theoria.Obligation`, `Theoria.Certificate`, and `Theoria.Certificate.Report` — experimental checked-claim/certificate layer for tools.
- `Theoria.Typespec` and `Theoria.Typespec.*` — experimental normalized Elixir typespec facts.
- `Theoria.Spec.*` — experimental finite fact/claim vocabularies for tool integrations.
- `Theoria.Equation.Summary`, `Theoria.Equation.Report`, `Theoria.Theorem.Report`, `Theoria.Theorem.ModuleReport`, `Theoria.Simp.Report`, and `Theoria.Simp.ExampleReport` — structured report data for public CLI/API workflows.

## Experimental public APIs

These are useful but may change before 1.0:

- `Theoria.Equation` — equation compilation/realization facade. The ordinary equation, unfold identity, all-identity, summary, and realization helpers are the preferred 0.8-facing entrypoints.
- `Theoria.Rewrite`, `Theoria.Simp` — proof-producing rewrite/simp helpers.
- report structs under `Theoria.Kernel.*Report` and deeper assurance report modules.

Prefer documented facade functions and accessors instead of depending on internal struct layout. Module documentation is the primary API reference; guide pages explain workflows and stability posture.

## Internal and contributor APIs

These support generated artifacts, assurance, and contributor-only validation. They may change without compatibility shims before 1.0:

- `Theoria.Equation.Matcher.*` — matcher equation lookup/planning remains experimental.
- `Theoria.Equation.Matcher.Indexed.*` — indexed matcher APIs are explicit validation/contributor surfaces, not stable user APIs.
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
mix theoria.theorems --json --install MyApp.Proofs
mix theoria.typespecs MyApp.Context --json
mix theoria.validate
mix theoria.kernel.check
mix theoria.kernel.check --assurance-summary
```

Experimental CLI workflows:

```bash
mix theoria.equations --json --realize nat_add
mix theoria.simp nat_add_zero --prove --json
mix theoria.simp nat_add_zero --prove --explain
mix theoria.lean.check
```
