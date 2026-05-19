# Kernel spec

Theoria's trusted base is the native Elixir kernel. This document describes the Elixir-authored reference path used for differential assurance.

## Trusted modules

The trusted runtime boundary is centered on:

- `Theoria.Kernel`
- `Theoria.Normalize`
- `Theoria.Term`
- `Theoria.Context`
- `Theoria.Env`

Automation such as DSL expansion, theorem macros, equation compilation, matcher planning, rewrite/simp search, CLI rendering, and Lean encoding is untrusted. Their outputs matter only after native kernel checking. The Reach architecture policy also forbids the kernel layer from depending on the DSL, library modules, rewrite/simp automation, Lean encoding, or Mix task entrypoints.

## Supported reference fragment

The reference checker now covers these core terms:

- `Sort`
- `Const`
- `App`
- `Lam`
- `Forall`
- `BVar`
- `Let`
- `Eq`
- `Refl`
- `EqRec`

Later phases still need deeper independent coverage for:

- full inductive/recursor reference validation
- matcher declarations
- environment replay
- deeper theorem-module reference coverage beyond the built-in theorem corpus
- broader randomized well-typed term generation

Differential checks use a curated corpus that stays inside the explicitly supported reference fragment.

## Judgments

The reference path mirrors four judgments:

```text
infer(env, context, term) -> type
check(env, context, term, expected_type) -> ok | error
normalize(env, term) -> term
defeq(env, left, right) -> boolean
```

`Theoria.Kernel.Reference.Normalize` provides a separate slow reference normalizer for beta, let, transparent constant unfolding, reference primitive reductions, and `EqRec` over `Refl`. `Theoria.Kernel.Reference.Primitive` mirrors recursor iota reduction using the reference definitional-equality path for indexed rule matching, so reference normalization no longer calls production `Theoria.Normalize.Primitive`. The reference checker uses that path for WHNF and definitional equality.

Definitional equality compares normalized core terms through `Theoria.Term.equivalent?/2`: diagnostic binder names are ignored, while de Bruijn indices carry binding identity. Universe levels are normalized before comparison, including canonical `max` ordering for commutativity/associativity cases.

## Differential assurance

`Theoria.Kernel.Differential` compares production kernel results against `Theoria.Kernel.Reference` on the curated kernel corpus, including Bool/Nat/List/Vec examples, rejected inference/checking cases, generated equation artifacts, explicit indexed matcher artifacts, deterministic generated declaration-chain, let-chain, theorem-chain, universe-polymorphic environments, and invalid environment rejection cases, the built-in theorem modules, reference replay of environment declarations, theorem-module-installed environment replay, and replay of environments extended with generated artifacts. Property tests also generate closed Bool, Nat, List Bool, Vec Bool, typed dependent fragments, and `EqRec` over reflexivity, plus generated equalities and List eliminator applications, then compare production inference, checking, and normalization with the reference path.

Run it with:

```bash
mix theoria.kernel.check
mix theoria.kernel.check --verbose
mix theoria.kernel.check --json
mix theoria.kernel.check --coverage
mix theoria.kernel.check --json --coverage
```

Verbose and coverage modes report ordinary environment replay separately from generated-artifact replay. Artifact replay installs generated and indexed equation artifacts into suitable environments and then replays those declarations through the reference path. Any skipped artifact is reported by structured identity and reason; a skip is not a proof failure, but it marks a boundary that was not replayed as an installed declaration.

This is assurance groundwork, not a formal proof that the Elixir kernel is correct. The goal is to keep the maintained source Elixir-first while adding an independent, explicit, slower reference path that catches regressions in the trusted kernel.
