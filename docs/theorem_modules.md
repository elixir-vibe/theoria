# Theorem Modules

Theoria theorem modules are ordinary Elixir modules that `use Theoria.DSL` and declare checked theorem functions with the `theorem` macro. See `examples/theorem_module/run.exs` for a small runnable workflow.

```elixir
defmodule MyApp.Proofs do
  use Theoria.DSL

  theorem :true_is_true do
    type do
      const(:True)
    end

    proof do
      const(:true_intro)
    end
  end
end
```

For each theorem, the macro generates three documented functions:

- `<name>_type/0` returns unelaborated type syntax.
- `<name>_proof/0` returns unelaborated proof syntax.
- `<name>_theorem/1` elaborates and checks the theorem against an environment.

Theorems may be universe-polymorphic:

```elixir
theorem :identity, universes: [:u] do
  type do
    term do
      forall :a, sort(u) do
        a ~> a
      end
    end
  end

  proof do
    term do
      lam :a, sort(u) do
        lam :x, a do
          x
        end
      end
    end
  end
end
```

The macro also registers theorem names through `__theoria_theorems__/0`, which lets tooling check a whole module:

```elixir
{:ok, env} = Theoria.Prelude.env()
{:ok, theorems} = Theoria.Theorem.check_all(MyApp.Proofs, env)
```

Checked theorems can also be installed into an environment as opaque theorem declarations. This lets later theorems refer to earlier theorem constants without making proofs unfold during normalization:

```elixir
{:ok, env} = Theoria.Prelude.env()
{:ok, env, theorems} = Theoria.Theorem.add_all_to_env(MyApp.Proofs, env)
```

A checked theorem's trusted assumptions can be inspected with:

```elixir
{:ok, axioms} = Theoria.Theorem.axioms(env, theorem)
```

From Mix, use:

```bash
mix theoria.theorems MyApp.Proofs
mix theoria.theorems --install MyApp.Proofs
mix theoria.theorems --axioms MyApp.Proofs
mix theoria.validate --only logic
```

`mix theoria.theorems` checks theorem modules against `Theoria.Prelude.env/0`. Named downstream modules are loaded directly from the project code path. With `--install`, theorem modules are checked sequentially and installed as opaque theorem declarations, so later theorems/modules can refer to earlier theorem constants. With `--axioms`, the task reports trusted axiom assumptions used by each theorem module.

`mix theoria.check` runs the full native validation corpus, including theorem modules, definitional-equality checks, and inductive specs. Use `mix theoria.validate --only CATEGORY` to narrow validation while developing.

The generated theorem functions are intentionally normal Elixir functions so ExDoc can document them alongside their surrounding module docs.

## Quoted term DSL

Inside `term do ... end`, bare lowercase names become named variables and function calls become constant applications:

```elixir
term do
  and_intro(q, p, and_right(p, q, h), and_left(p, q, h))
end
```

The quote DSL also supports binder and helper forms:

```elixir
term do
  forall :p, prop() do
    p ~> p
  end
end

term do
  lam :f, p ~> q do
    lam :x, p do
      let :result, q, app(f, x) do
        result
      end
    end
  end
end
```

Generator code can splice pre-built syntax and universe levels with `^`:

```elixir
u = Theoria.Level.param(:u)
nat = Theoria.Syntax.const(:Nat)

term do
  forall :a, sort(^u) do
    ^nat ~> a
  end
end
```

Because `and`, `or`, and `not` are reserved Elixir words, theorem code should use the readable aliases `conj(p, q)` and `neg(p)` for the object-language constants `:and` and `:not`.

The quote DSL also provides aliases for constants that are awkward or ambiguous in Elixir syntax:

```elixir
term do
  eq(bool(), bool_not(bool_true()), bool_false())
end

term do
  forall :n, nat() do
    eq(nat(), nat_add(zero, n), n)
  end
end

term do
  true_prop() ~> false_prop()
end
```

`bool()` and `nat()` refer to computational types. `bool_true()` and `bool_false()` refer to computational Bool constructors. `true_prop()` and `false_prop()` refer to logical propositions `True` and `False`.

If unsupported Elixir syntax appears inside a term block, the DSL raises targeted errors for common mistakes such as lists, tuples, strings, numbers, malformed binders, and uppercase `Bool`/`Nat`/`List` aliases.
