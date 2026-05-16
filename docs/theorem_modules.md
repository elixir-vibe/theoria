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
