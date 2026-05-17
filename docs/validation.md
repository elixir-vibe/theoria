# Theoria validation

Theoria owns its validation corpus. External tools such as Lean consume this corpus, but they do not decide which examples, theorem modules, or reduction checks matter.

Run native validation with:

```bash
mix theoria.validate
```

To narrow the corpus while developing:

```bash
mix theoria.validate --only bool
mix theoria.validate --only nat,list
mix theoria.validate --only defeq
mix theoria.validate --only inductives
```

## What is validated

`Theoria.Validation.Corpus` currently contains three kinds of checks:

| Check | Source | Native checker |
|---|---|---|
| Theorem modules | `Theoria.Library.*.Theorems` | `Theoria.Theorem.check_all/2` |
| Definitional equality | `%Theoria.Validation.DefeqCheck{}` | `Theoria.Normalize.defeq?/3` |
| Inductive specs | `%Theoria.Validation.InductiveCheck{}` | `Theoria.Inductive.check_spec/2` and `Theoria.Inductive.verify_env/2` |

The default corpus covers Logic, Equality, Bool, Nat, List, and Vec theorem modules, built-in reduction checks, deterministic small normalized Bool/Nat/List/Vec terms, and the built-in inductive specs.

## Defeq checks

Defeq checks are first-class Theoria values:

```elixir
%Theoria.Validation.DefeqCheck{
  category: :nat,
  name: "nat_add_one_zero",
  left: left,
  right: right
}
```

They are checked by Theoria before any external oracle sees them:

```elixir
Theoria.Validation.DefeqCheck.check(env, check)
```

Use these for kernel reduction behavior such as beta, zeta, recursor iota, indexed iota, and small deterministic normalized examples.

## Lean oracle boundary

Lean validation is optional contributor hardening:

```bash
mix theoria.lean.check
```

It translates the Theoria validation corpus into Lean source and asks Lean to check the same proof and defeq claims. Lean is not Theoria's source of truth and is not required for normal use.

## Adding new checks

Prefer adding validation data close to the Theoria feature it exercises:

1. Add a theorem to the appropriate `Theoria.Library.*.Theorems` module when it is a reusable library fact.
2. Add a `%Theoria.Validation.DefeqCheck{}` when the point is definitional equality or reduction behavior.
3. Add an inductive check when a built-in spec/declaration shape needs to stay validated.

After adding checks, run:

```bash
mix theoria.validate
mix theoria.lean.check
```
