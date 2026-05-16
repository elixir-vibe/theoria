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

{:ok, report} = Inductive.report(spec)
report.declarations
#=> [:Switch, :on, :off, :switch_rec, :switch_ind]
```

For parameterized families, declare named parameters explicitly. The validator checks that constructor result arguments preserve those parameters for non-indexed families:

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

The built-in `Bool`, `Nat`, and `List` libraries use this same path. Their recursors and inductors are generated from recognized constructor shapes and checked against the kernel before entering the environment.
