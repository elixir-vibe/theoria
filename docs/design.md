# Theoria Design

Theoria is an Elixir-native proof/spec engine inspired by Lean's trusted-kernel architecture. It is not a Lean-compatible implementation and does not call Lean as a backend.

## Goals

- Provide a small trusted kernel for checking proof terms.
- Keep Elixir DSLs, tactics, and automation untrusted: they may generate proofs, but the kernel must check them.
- Support practical specifications for Elixir tools, static analysis, graph algorithms, compiler passes, and data transformations.
- Fit naturally into Elixir projects and CI pipelines.
- Keep data structures friendly to Elixir's gradual set-theoretic type direction by using precise structs and explicit result tuples.

## Non-goals

- Lean syntax compatibility.
- Lean `.olean` compatibility.
- A tactic language in the initial kernel.
- Native code generation.
- A full standard library before the kernel is hardened.

## Trusted boundary

Only `Theoria.Kernel` should decide whether a proof is accepted. Higher-level APIs may be convenient but must remain untrusted.

The intended flow is:

```text
Elixir DSL / tactic / domain-specific prover
  -> named Theoria.Syntax terms
  -> Theoria.Elaborator
  -> core Theoria.Term terms
  -> Theoria.Kernel.check/4
  -> checked theorem or error
```

A bug in a DSL should at worst generate a rejected proof. It must not be able to admit a theorem directly.

## Core terms

The initial core calculus contains:

- universes, represented as `Sort n`;
- de Bruijn bound variables;
- constants;
- application;
- lambda abstraction;
- dependent function types (`forall`);
- propositional equality;
- reflexivity proofs.

Names stored on core binders are diagnostic metadata. Binding correctness is determined by de Bruijn indices.

## Named syntax

`Theoria.Syntax` provides named surface terms and `Theoria.Elaborator` converts them to de Bruijn-indexed core terms. This layer is untrusted and exists to make library definitions auditable without hand-maintaining indices.

`Theoria.DSL` adds Elixir-friendly `do` block constructors on top of named syntax. It also remains untrusted: it only builds syntax terms or generates functions that elaborate syntax and call the kernel.

The `theorem` macro creates a small function trio: `<name>_type/0`, `<name>_proof/0`, and `<name>_theorem/1`. The final function returns a `Theoria.Theorem` only after kernel checking succeeds.

## Environments

`Theoria.Env` stores checked constants and definitions. A declaration enters the environment only through kernel functions that verify its type and, for definitions, its value.

## Normalization and definitional equality

The initial normalizer supports beta reduction and unfolding checked definitions. Definitional equality currently normalizes both sides and compares the resulting terms structurally.

This is intentionally simple. Later versions may need weak-head reduction, memoization, fuel, and more careful unfolding control.

## Universe model

The current prototype uses a simple cumulative-looking tower where:

```text
Sort n : Sort (n + 1)
```

There is no separate `Prop` yet. Equality currently infers `Sort 0` as a proposition-like type. This is intentionally provisional and should be revisited when the logic layer grows.

## Inspect and pretty-printing

Core terms and checked theorems implement Elixir's `Inspect` protocol via `Theoria.Pretty`. This keeps everyday `IO.inspect/1`, `dbg/1`, and assertion failures readable while preserving pure rendering functions for future UI and documentation use.

## Relationship to Elixir set-theoretic types

Elixir's set-theoretic types describe sets of Elixir runtime values. Theoria checks terms in its own object language. These are complementary:

- Elixir types help make Theoria's implementation and API safer.
- Theoria's kernel checks mathematical proof/spec terms that Elixir's type system does not express.

## Logic library

`Theoria.Library.Logic` extends an environment with the first logical declarations. It keeps logic outside the kernel where possible: `not` is a checked definition, while `False`, `True`, `and`, and constructors/eliminators are environment constants for now.

This is a pragmatic bootstrap point. Once the calculus grows inductive families and a clearer `Prop` story, some primitive logical constants can be revisited as library-defined encodings.

## Near-term roadmap

1. Add elimination/projection helpers for logical connectives.
2. Add primitive Bool/Nat/List theories.
3. Add proof modules for larger theorem corpora.
4. Add finite graph/spec libraries for tools such as Reach.
