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
mix theoria.lean.check --only equality
mix theoria.lean.check --only bool,nat,list,vec
mix theoria.lean.check --only defeq
```

If Lean is missing, the task fails with installation guidance. Normal `mix ci` does not require Lean.

## Architecture

Theoria owns the validation corpus described in [`validation.md`](validation.md). The Lean subsystem is only a translation and external-checking layer.

| Module | Responsibility |
|---|---|
| `Theoria.Lean.Encodable` | Protocol for rendering Theoria structures as Lean source |
| `Theoria.Lean.Encode` | Public encoding facade and Lean syntax helpers |
| `Theoria.Lean.Encode.Term` | Protocol implementations for core term structs |
| `Theoria.Lean.Encode.Application` | Lean-specific application spine encoders for recursors and implicit arguments |
| `Theoria.Lean.MirrorPrelude` | Small bridge declarations for primitives not mapped directly to Lean core |
| `Theoria.Lean.Mirror.Inductive` | Oracle-only Lean inductive declarations generated from supported Theoria specs |
| `Theoria.Validation.Corpus` | Chooses Theoria theorem modules and definitional-equality checks |
| `Theoria.Validation.DefeqCheck` | First-class Theoria-owned defeq check, locally checkable by the normalizer |
| `Theoria.Lean.Module` | Builds complete Lean source files from already-selected Theoria checks |
| `Theoria.Lean.Corpus` | Thin adapter from `Theoria.Validation.Corpus` to `Theoria.Lean.Module` |
| `Theoria.Lean.Oracle` | Writes generated source and invokes the Lean executable |

Generated files are build artifacts and should not be committed.

## Scope

The native Theoria validation corpus also includes Logic theorem modules. The current Lean-supported fragment validates the primitive equality, Bool, Nat, List, and Vec theorem corpora plus definitional-equality checks for beta, zeta, Bool computation, Nat recursor iota, Nat addition, List length, List recursor iota, Vec indexed iota, and deterministic small normalized Bool/Nat/List/Vec terms.

The encoding boundary is intentionally narrow:

1. Theoria theorem modules and `Theoria.Validation.DefeqCheck` values are selected before Lean is involved.
2. Theoria checked core terms are rendered through `Theoria.Lean.Encodable`.
3. The encoder reuses Lean-native constants where possible: `Bool`, `Nat`, `List`, their constructors, and Lean recursors.
4. Lean-specific argument order, implicit arguments, and recursor spines are handled in `Theoria.Lean.Encode.Application`.
5. Handwritten Lean is limited to tiny bridge definitions whose semantics differ from Lean's defaults, such as `tEqRec` and Theoria's first-argument `tNatAdd`.
6. Custom inductives are generated from `Theoria.Inductive.Spec`; the current generated fallback covers Theoria's Vec shape because Lean's built-in `Vector` is array-backed and does not match Theoria's constructor-level indexed family.

The subsystem is intentionally incremental: as protocol encoders grow, random kernel fragments and broader custom inductive generation can be added.

Lean oracle validation increases confidence in Theoria's kernel, but it is not a formal proof of the Elixir implementation. A later formalization could define Theoria's syntax and typing rules inside Lean and prove soundness there.
