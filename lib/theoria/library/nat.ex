defmodule Theoria.Library.Nat do
  @moduledoc """
  Initial natural number declarations and primitive recursion.
  """

  alias Theoria.Env
  alias Theoria.Equation
  alias Theoria.Equation.{Clause, Pattern}
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

    %Spec{spec | recursors: Generate.eliminators!(spec)}
  end

  defp succ_type do
    elab!(arrow(const(:Nat), const(:Nat)))
  end

  defp nat_add_type do
    elab!(arrow(const(:Nat), arrow(const(:Nat), const(:Nat))))
  end

  defp nat_add_value do
    {:ok, body} =
      Equation.compile_nat(
        Theoria.Term.const(:Nat),
        [
          Clause.new([Pattern.constructor(:zero)], Theoria.Term.bvar(0)),
          Clause.new([Pattern.constructor(:succ, [Pattern.var(:pred)])], nat_add_succ_case())
        ],
        Theoria.Term.bvar(1)
      )

    Theoria.Term.lam(
      :m,
      Theoria.Term.const(:Nat),
      Theoria.Term.lam(:n, Theoria.Term.const(:Nat), body)
    )
  end

  defp nat_add_succ_case do
    Theoria.Term.lam(
      :_pred,
      Theoria.Term.const(:Nat),
      Theoria.Term.lam(
        :acc,
        Theoria.Term.const(:Nat),
        Theoria.Term.app(Theoria.Term.const(:succ), Theoria.Term.bvar(0))
      )
    )
  end
end
