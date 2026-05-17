# Lean oracle validation

Theoria can generate Lean source from a checked fragment of its core terms and use Lean as an external oracle during development.

This is contributor tooling. Lean is not required to use Theoria as a library, and Theoria never depends on Lean at runtime.

## Workflow

Run:

```bash
mix theoria.lean.check
```

The task:

1. Collects the current Lean oracle corpus.
2. Renders a Lean file under `_build/theoria_lean/oracle.lean`.
3. Runs `lean` on that file.
4. Reports whether Lean accepted the generated checks.

Set a custom executable or output path when needed:

```bash
THEORIA_LEAN=/path/to/lean mix theoria.lean.check
mix theoria.lean.check --lean /path/to/lean --path /tmp/theoria_oracle.lean
```

If Lean is missing, the task fails with installation guidance. Normal `mix ci` does not require Lean.

## Architecture

The Lean oracle subsystem lives under `Theoria.Lean.*`:

| Module | Responsibility |
|---|---|
| `Theoria.Lean.Encodable` | Protocol for rendering Theoria structures as Lean source |
| `Theoria.Lean.Encode` | Public encoding facade and Lean syntax helpers |
| `Theoria.Lean.MirrorPrelude` | Small bridge declarations for primitives not mapped directly to Lean core |
| `Theoria.Lean.Module` | Builds complete Lean source files from proof/defeq checks |
| `Theoria.Lean.Corpus` | Chooses theorem modules and fixtures for the oracle corpus |
| `Theoria.Lean.Oracle` | Writes generated source and invokes the Lean executable |

Generated files are build artifacts and should not be committed.

## Scope

The current corpus validates the primitive equality, Bool, and Nat theorem corpora plus definitional-equality fixtures for beta, zeta, Bool computation, Nat recursor iota, and Nat addition. The encoder reuses Lean-native Bool/Nat/List constants where possible and keeps handwritten Lean to small bridge definitions such as `tEqRec` and Theoria's first-argument `tNatAdd`. The subsystem is intentionally incremental: as protocol encoders grow, List, Vec, indexed iota, and random kernel fragments can be added.

Lean oracle validation increases confidence in Theoria's kernel, but it is not a formal proof of the Elixir implementation. A later formalization could define Theoria's syntax and typing rules inside Lean and prove soundness there.
