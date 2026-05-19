# Kernel spec

Theoria's trusted base is the native Elixir kernel. This document describes the first Elixir-authored reference-checker fragment used for differential assurance.

## Trusted modules

The trusted runtime boundary is centered on:

- `Theoria.Kernel`
- `Theoria.Normalize`
- `Theoria.Term`
- `Theoria.Context`
- `Theoria.Env`

Automation such as DSL expansion, theorem macros, equation compilation, matcher planning, rewrite/simp search, CLI rendering, and Lean encoding is untrusted. Their outputs matter only after native kernel checking.

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
- a reference normalizer independent of `Theoria.Normalize`

Differential checks use a curated corpus that stays inside the explicitly supported reference fragment.

## Judgments

The reference fragment mirrors three judgments:

```text
infer(env, context, term) -> type
check(env, context, term, expected_type) -> ok | error
defeq(env, left, right) -> boolean
```

The reference checker uses the production normalizer for definitional equality in this initial phase. Later phases can split out a reference normalizer.

## Differential assurance

`Theoria.Kernel.Differential` compares production kernel results against `Theoria.Kernel.Reference` on the curated kernel corpus.

Run it with:

```bash
mix theoria.kernel.check
```

This is assurance groundwork, not a formal proof that the Elixir kernel is correct. The goal is to keep the maintained source Elixir-first while adding an independent, explicit, slower reference path that catches regressions in the trusted kernel.
