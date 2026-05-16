defmodule Theoria.Library.Nat do
  @moduledoc """
  Initial natural number declarations and primitive recursion.
  """

  alias Theoria.Env
  alias Theoria.Inductive.Generate
  alias Theoria.Inductive.Spec
  alias Theoria.Kernel

  import Theoria.DSL, except: [type: 1]

  @doc "The core universe for `Type 0`."
  def type, do: Theoria.Term.sort(1)

  @doc "Extends an environment with natural number declarations."
  def extend(%Env{} = env) do
    with {:ok, env} <- Kernel.add_inductive(env, inductive_spec()) do
      Kernel.add_definition(env, :nat_add, nat_add_type(), nat_add_value())
    end
  end

  @doc "Returns a new environment extended with natural number declarations."
  def env do
    extend(Env.new())
  end

  @doc "Returns the inductive specification described by this library."
  def inductive_spec do
    spec =
      :Nat
      |> Spec.new(type(), universe_params: [:u])
      |> Spec.constructor(:zero, Theoria.Term.const(:Nat))
      |> Spec.constructor(:succ, succ_type())

    %Spec{spec | recursors: Generate.nat_eliminators(spec)}
  end

  defp succ_type do
    elab!(arrow(const(:Nat), const(:Nat)))
  end

  defp nat_add_type do
    elab!(arrow(const(:Nat), arrow(const(:Nat), const(:Nat))))
  end

  defp nat_add_value do
    elab!(
      lam :m, const(:Nat) do
        lam :n, const(:Nat) do
          call(
            const(:nat_rec, [1]),
            const(:Nat),
            var(:n),
            lam :_pred, const(:Nat) do
              lam :acc, const(:Nat) do
                call(const(:succ), var(:acc))
              end
            end,
            var(:m)
          )
        end
      end
    )
  end
end
