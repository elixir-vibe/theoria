defmodule Theoria.Library.Logic do
  @moduledoc """
  Basic logical constants and checked definitions.

  This module intentionally builds logic as environment declarations instead of
  adding more trusted kernel terms. `False`, `True`, `and`, and their
  eliminators/constructors are primitive constants for now; `not` is a checked
  definition on top of the core calculus.
  """

  alias Theoria.Env
  alias Theoria.Kernel

  import Theoria.DSL, except: [prop: 0]

  @doc "The proposition universe used by the initial logic library."
  def prop, do: core_prop()

  @doc "Extends an environment with the initial logical constants and definitions."
  def extend(%Env{} = env) do
    with {:ok, env} <- Kernel.add_constant(env, :False, prop()),
         {:ok, env} <- Kernel.add_constant(env, :True, prop()),
         {:ok, env} <- Kernel.add_constant(env, :true_intro, Theoria.Term.const(:True)),
         {:ok, env} <- Kernel.add_constant(env, :false_elim, false_elim_type()),
         {:ok, env} <- Kernel.add_definition(env, :not, not_type(), not_value()),
         {:ok, env} <- Kernel.add_constant(env, :and, and_type()),
         {:ok, env} <- Kernel.add_constant(env, :and_intro, and_intro_type()),
         {:ok, env} <- Kernel.add_constant(env, :and_left, and_left_type()) do
      Kernel.add_constant(env, :and_right, and_right_type())
    end
  end

  @doc "Returns a new environment extended with the initial logic library."
  def env do
    extend(Env.new())
  end

  defp false_elim_type do
    elab!(
      forall :a, Theoria.DSL.prop() do
        arrow(const(:False), var(:a))
      end
    )
  end

  defp not_type do
    elab!(
      forall :p, Theoria.DSL.prop() do
        Theoria.DSL.prop()
      end
    )
  end

  defp not_value do
    elab!(
      lam :p, Theoria.DSL.prop() do
        arrow(var(:p), const(:False))
      end
    )
  end

  defp and_type do
    elab!(
      forall :p, Theoria.DSL.prop() do
        forall :q, Theoria.DSL.prop() do
          Theoria.DSL.prop()
        end
      end
    )
  end

  defp and_intro_type do
    elab!(
      forall :p, Theoria.DSL.prop() do
        forall :q, Theoria.DSL.prop() do
          forall :hp, var(:p) do
            forall :hq, var(:q) do
              call(const(:and), var(:p), var(:q))
            end
          end
        end
      end
    )
  end

  defp and_left_type do
    elab!(
      forall :p, Theoria.DSL.prop() do
        forall :q, Theoria.DSL.prop() do
          forall :h, call(const(:and), var(:p), var(:q)) do
            var(:p)
          end
        end
      end
    )
  end

  defp and_right_type do
    elab!(
      forall :p, Theoria.DSL.prop() do
        forall :q, Theoria.DSL.prop() do
          forall :h, call(const(:and), var(:p), var(:q)) do
            var(:q)
          end
        end
      end
    )
  end
end
