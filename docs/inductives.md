# Inductive specifications

Theoria describes primitive inductive families with data structs, then admits the resulting declarations through the kernel. The DSL and spec builders are untrusted conveniences; `Theoria.Kernel.add_inductive/2` is the admission boundary.

A small Bool-like family can be written with constructors only and completed with generated eliminators:

```elixir
alias Theoria.{Env, Inductive, Kernel}
alias Theoria.Inductive.Spec

import Theoria.DSL

spec =
  :Switch
  |> Spec.new(term(do: sort(1)) |> elab!())
  |> Spec.constructor(:on, term(do: const(:Switch)) |> elab!())
  |> Spec.constructor(:off, term(do: const(:Switch)) |> elab!())

{:ok, spec} = Inductive.complete(spec)
{:ok, env} = Kernel.add_inductive(Env.new(), spec)
```

You can inspect the shape and declaration plan before admission:

```elixir
Inductive.shape(spec)
#=> :bool_like

shape = Inductive.classify(spec)
shape.constructors.first.name
#=> :on

{:ok, report} = Inductive.report(spec)
report.declarations
#=> [:Switch, :on, :off, :switch_rec, :switch_ind]
```

For parameterized families, declare named parameters explicitly. The validator checks that constructor result arguments preserve those parameters:

```elixir
u = Theoria.Level.param(:u)

type =
  term do
    forall :a, sort(^u) do
      sort(^u)
    end
  end
  |> elab!()

spec =
  :List
  |> Spec.new(type, universe_params: [:u, :v])
  |> Spec.parameter(:a, term(do: sort(^u)) |> elab!())
```

Indexed families can declare named indices. The current checker validates result arity, parameter preservation, and scopedness of constructor argument/index terms; it does not synthesize indexed eliminators yet. Environment-backed admission also requires dependencies to be present. For example, this Vec-like spec must be checked in an environment that already contains `Nat`, `zero`, and `succ`.

```elixir
u = Theoria.Level.param(:u)

vec_type =
  term do
    forall :a, sort(^u) do
      nat() ~> sort(^u)
    end
  end
  |> elab!()

spec =
  :Vec
  |> Spec.new(vec_type, universe_params: [:u])
  |> Spec.parameter(:a, term(do: sort(^u)) |> elab!())
  |> Spec.index(:n, term(do: nat()) |> elab!())
```

The built-in `Bool`, `Nat`, and `List` libraries use this same path. Their recursors and inductors are generated from structured classifications of recognized constructor shapes and checked against the kernel before entering the environment.
