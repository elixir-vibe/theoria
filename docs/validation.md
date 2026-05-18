# Theoria validation

Theoria owns its validation corpus. External tools such as Lean consume this corpus, but they do not decide which examples, theorem modules, or reduction checks matter.

Run native validation with:

```bash
mix theoria.validate
```

Check a downstream theorem module with:

```bash
mix theoria.theorems MyApp.Proofs
```

To narrow the corpus while developing:

```bash
mix theoria.validate --only bool
mix theoria.validate --only nat,list
mix theoria.validate --only defeq
mix theoria.validate --only inductives
mix theoria.validate --axioms
```

## What is validated

`Theoria.Validation.Corpus` currently contains three kinds of checks:

| Check | Source | Native checker |
|---|---|---|
| Theorem modules | `Theoria.Library.*.Theorems` via `Theoria.Validation.TheoremModuleCheck` | `Theoria.Validation.Checkable` / `Theoria.Theorem.check_all/2` |
| Definitional equality | `%Theoria.Validation.DefeqCheck{}` | `Theoria.Validation.Checkable` / `Theoria.Normalize.defeq?/3` |
| Inductive specs | `%Theoria.Validation.InductiveCheck{}` | `Theoria.Validation.Checkable` / `Theoria.Inductive.check_spec/2` and `Theoria.Inductive.verify_env/2` |
| Explicit indexed matcher spec | Internal Vec matcher validation | `Theoria.Equation.Matcher.Spec.indexed_from_info/2`, `Theoria.Kernel.add_matcher/2`, and `Theoria.Kernel.validate_env/1` |

The default corpus covers Logic, Equality, Bool, Nat, List, and Vec theorem modules, built-in reduction checks, deterministic small normalized Bool/Nat/List/Vec terms, the built-in inductive specs, equation metadata, generated equation theorem realization, matcher equation realization, and one explicit indexed Vec matcher spec. The indexed matcher validation constructs and admits the matcher inside validation only; it is not installed by `Prelude.env/0` and does not yet generate matcher equations.

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

Prefer adding validation data close to the Theoria feature it exercises. Library validation metadata lives under modules such as `Theoria.Library.Bool.Validation`, `Theoria.Library.Nat.Validation`, `Theoria.Library.List.Validation`, and `Theoria.Library.Vec.Validation`.

Guidelines:

| Need | Put it in |
|---|---|
| Reusable proposition proof | `Theoria.Library.*.Theorems` |
| Reduction/iota/defeq behavior | `Theoria.Library.*.Validation` as `%Theoria.Validation.DefeqCheck{}` |
| Inductive declaration invariant | `Theoria.Library.*.Validation` as `%Theoria.Validation.InductiveCheck{}` |
| Shared validation term helper | `Theoria.Validation.Terms` |
| External oracle mapping issue | `Theoria.Lean.Encode.*` |

1. Add a theorem to the appropriate `Theoria.Library.*.Theorems` module when it is a reusable library fact.
2. Add a `%Theoria.Validation.DefeqCheck{}` in the owning library validation module when the point is definitional equality or reduction behavior.
3. Add an inductive check in the owning library validation module when a built-in spec/declaration shape needs to stay validated.

## Downstream theorem example

```elixir
defmodule MyApp.Proofs do
  use Theoria.DSL

  theorem :identity do
    type do
      term do
        forall :p, prop() do
          p ~> p
        end
      end
    end

    proof do
      term do
        lam :p, prop() do
          lam :hp, p do
            hp
          end
        end
      end
    end
  end
end

{:ok, env} = Theoria.Prelude.env()
Theoria.Theorem.check_all(MyApp.Proofs, env)
```

From Mix:

```bash
mix theoria.theorems MyApp.Proofs
```

After adding checks, run:

```bash
mix theoria.validate
mix theoria.lean.check
```
