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

`Theoria.Kernel.Reference.Normalize` provides a separate slow reference normalizer for beta, let, transparent constant unfolding, primitive reductions, and `EqRec` over `Refl`. The reference checker uses that path for WHNF and definitional equality.

## Differential assurance

`Theoria.Kernel.Differential` compares production kernel results against `Theoria.Kernel.Reference` on the curated kernel corpus and the built-in theorem modules. Property tests also generate closed Bool, Nat, and List Bool terms, plus Bool/Nat equalities and List eliminator applications, then compare production inference, checking, and normalization with the reference path.

Run it with:

```bash
mix theoria.kernel.check
mix theoria.kernel.check --json
```

This is assurance groundwork, not a formal proof that the Elixir kernel is correct. The goal is to keep the maintained source Elixir-first while adding an independent, explicit, slower reference path that catches regressions in the trusted kernel.
