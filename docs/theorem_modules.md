# Theorem Modules

Theoria theorem modules are ordinary Elixir modules that `use Theoria.DSL` and declare checked theorem functions with the `theorem` macro.

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

The macro also registers theorem names through `__theoria_theorems__/0`, which lets tooling check a whole module:

```elixir
{:ok, env} = Theoria.Prelude.env()
{:ok, theorems} = Theoria.Theorem.check_all(MyApp.Proofs, env)
```

From Mix, use:

```bash
mix theoria.check MyApp.Proofs
```

With no module arguments, `mix theoria.check` checks Theoria's built-in theorem corpora against `Theoria.Prelude.env/0`.

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
    arrow(p, p)
  end
end

term do
  lam :f, arrow(p, q) do
    lam :x, p do
      app(f, x)
    end
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
  arrow(true_prop(), false_prop())
end
```

`bool()` and `nat()` refer to computational types. `bool_true()` and `bool_false()` refer to computational Bool constructors. `true_prop()` and `false_prop()` refer to logical propositions `True` and `False`.

If unsupported Elixir syntax appears inside a term block, the DSL raises targeted errors for common mistakes such as lists, tuples, strings, numbers, malformed binders, and uppercase `Bool`/`Nat`/`List` aliases.
