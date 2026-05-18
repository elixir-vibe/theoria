# Theoria 0.1 release boundary

Theoria 0.1 is an experimental first release of the Elixir-native proof/spec kernel. The goal is to publish a small, auditable foundation for checked proof terms and validation workflows, not a complete Lean-compatible proof assistant.

## Included in 0.1

- A small dependent term kernel with explicit environments and checked declarations.
- De Bruijn-indexed core terms with named syntax and DSL helpers on top.
- Definitions, theorems, axioms, opacity, trust reporting, and environment replay validation.
- Primitive equality terms and untrusted equality-construction helpers.
- Inductive specifications, generated constructors/recursors/inductors, and iota metadata.
- Built-in libraries for Logic, Equality, Bool, Nat, List, and Vec.
- Theorem modules and Mix tasks for theorem-only workflows.
- Native validation corpus and `mix theoria.check` / `mix theoria.validate`.
- Contributor-only Lean oracle validation through generated Lean source.
- Internal equation/matcher metadata for the current Bool/Nat/List fragment.
- Checked matcher declarations, generated ordinary equations, matcher equations, and unfold equations.
- Experimental rewrite/simp groundwork that consumes generated equation metadata.
- ExDoc guides and release-facing README documentation.

## Explicitly outside 0.1

- Stable public equation-definition syntax.
- Stable tactic API.
- Proof-producing simplification or rewrite tactics.
- General structural recursion checking.
- `brecOn` / below-style recursion machinery.
- Dependent/indexed matcher descriptors such as Vec matchers.
- Full Lean-style fixed-parameter permutations or mutual recursion support.
- Persistent Lean-style theorem/matcher equation environment extensions.
- A commitment that internal equation, rewrite, simp, or Lean-oracle modules are stable before 0.2.

## Trusted boundary

The trusted runtime boundary is intentionally narrow:

- `Theoria.Kernel` checks terms and admits declarations.
- `Theoria.Env` stores checked declarations and metadata.
- Environment replay validates declarations through kernel entrypoints.

Everything else is untrusted convenience or tooling. DSLs, theorem macros, equation compilation, matcher descriptor/type generation, rewrite/simp helpers, validation corpus construction, and Lean encoding produce artifacts that must still be checked by the native kernel before they are trusted.

The Lean oracle is contributor confidence only. Lean is not a runtime dependency, source of truth, or trusted component of Theoria.

## API stability for 0.1

Stable-ish entrypoints:

- `Theoria`
- `Theoria.Term`
- `Theoria.Kernel`
- `Theoria.Env`
- `Theoria.Normalize`
- `Theoria.DSL`
- `Theoria.Theorem`
- `Theoria.Prelude`
- `Theoria.Inductive`
- `Theoria.Inductive.Spec`
- `Theoria.Validation`

Experimental/internal entrypoints:

- `Theoria.Equation.*`
- `Theoria.Rewrite.*`
- `Theoria.Simp.*`
- `Theoria.Lean.*`
- elaborator and syntax internals not shown in README examples

Experimental modules are documented for auditability, but their APIs may change before 0.2.

## Release checklist

Before publishing 0.1, run:

```bash
mix deps.unlock --check-unused
mix format --check-formatted
mix ci
mix docs
mix hex.build
mix theoria.lean.check
```

Publishing currently requires an interactive Hex 2FA code:

```bash
mix hex.publish package
```
