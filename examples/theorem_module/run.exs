defmodule ExampleProofs do
  @moduledoc false

  use Theoria.DSL

  theorem :identity do
    type do
      forall :a, type(0) do
        forall :x, var(:a) do
          var(:a)
        end
      end
    end

    proof do
      lam :a, type(0) do
        lam :x, var(:a) do
          var(:x)
        end
      end
    end
  end

  theorem :identity_again do
    type do
      forall :a, type(0) do
        forall :x, var(:a) do
          var(:a)
        end
      end
    end

    proof do
      const(:identity)
    end
  end
end

{:ok, theorem} = ExampleProofs.identity_theorem()
{:ok, env, installed} = Theoria.Theorem.add_all_to_env(ExampleProofs, Theoria.new_env())

IO.puts("theorem: #{inspect(theorem.name)}")
IO.puts("registered: #{inspect(ExampleProofs.__theoria_theorems__())}")
IO.puts("installed: #{inspect(Enum.map(installed, & &1.name))}")
IO.puts("env declarations: #{length(Theoria.Env.declarations(env))}")
