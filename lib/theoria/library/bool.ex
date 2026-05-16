defmodule Theoria.Library.Bool do
  @moduledoc """
  Initial computational boolean declarations.

  This library introduces booleans as ordinary data in `Type 0`, distinct from
  the logical propositions `True` and `False` in `Theoria.Library.Logic`.
  """

  alias Theoria.Env
  alias Theoria.Inductive.Generate
  alias Theoria.Inductive.Spec
  alias Theoria.Kernel

  import Theoria.DSL, except: [type: 1]

  @doc "The core universe for `Type 0`."
  def type, do: Theoria.Term.sort(1)

  @doc "Extends an environment with boolean declarations."
  def extend(%Env{} = env) do
    with {:ok, env} <- Kernel.add_inductive(env, inductive_spec()),
         {:ok, env} <- Kernel.add_definition(env, :bool_not, bool_not_type(), bool_not_value()),
         {:ok, env} <- Kernel.add_definition(env, :bool_and, bool_binary_type(), bool_and_value()) do
      Kernel.add_definition(env, :bool_or, bool_binary_type(), bool_or_value())
    end
  end

  @doc "Returns a new environment extended with boolean declarations."
  def env do
    extend(Env.new())
  end

  @doc "Returns the inductive specification described by this library."
  def inductive_spec do
    spec =
      :Bool
      |> Spec.new(type(), universe_params: [:u])
      |> Spec.constructor(true, Theoria.Term.const(:Bool))
      |> Spec.constructor(false, Theoria.Term.const(:Bool))

    %Spec{spec | recursors: Generate.eliminators!(spec)}
  end

  defp bool_not_type do
    elab!(arrow(const(:Bool), const(:Bool)))
  end

  defp bool_not_value do
    elab!(
      lam :b, const(:Bool) do
        term do
          bool_rec(const(:Bool), false, true, b)
        end
      end
    )
  end

  defp bool_binary_type do
    elab!(
      arrow(
        const(:Bool),
        arrow(const(:Bool), const(:Bool))
      )
    )
  end

  defp bool_and_value do
    elab!(
      lam :a, const(:Bool) do
        lam :b, const(:Bool) do
          term do
            bool_rec(const(:Bool), b, false, a)
          end
        end
      end
    )
  end

  defp bool_or_value do
    elab!(
      lam :a, const(:Bool) do
        lam :b, const(:Bool) do
          term do
            bool_rec(const(:Bool), true, b, a)
          end
        end
      end
    )
  end
end
