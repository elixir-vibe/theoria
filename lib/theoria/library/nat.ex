defmodule Theoria.Library.Nat do
  @moduledoc """
  Initial natural number declarations and primitive recursion.
  """

  alias Theoria.Env
  alias Theoria.Equation
  alias Theoria.Equation.{Clause, Definition, FixedParams, Info, MatcherInfo, Pattern}
  alias Theoria.Equation.MatcherInfo.Alternative
  alias Theoria.Inductive.Generate
  alias Theoria.Inductive.Spec
  alias Theoria.Kernel
  alias Theoria.Term

  import Theoria.DSL, except: [type: 1]

  @doc "The core universe for `Type 0`."
  def type, do: Term.sort(1)

  @doc "Extends an environment with natural number declarations."
  def extend(%Env{} = env) do
    with {:ok, env} <- Kernel.add_inductive(env, inductive_spec()) do
      type = nat_add_type()
      value = nat_add_value()

      metadata =
        Info.new(:nat_add, type, value,
          rec_arg_pos: 0,
          fixed_params: FixedParams.new(),
          clauses: nat_add_clauses(),
          matcher: nat_matcher(:nat_add)
        )

      Kernel.add_definition(env, :nat_add, type, value, [], metadata: metadata)
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
      |> Spec.constructor(:zero, nat())
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
    n = Term.bvar(0)

    {:ok, body} =
      Equation.compile_nat(
        nat(),
        nat_add_clauses(n),
        Term.bvar(1)
      )

    nat_lam(:m, nat_lam(:n, body))
  end

  defp nat_add_clauses(n \\ Term.bvar(0)) do
    [
      Clause.new([Pattern.constructor(:zero)], n),
      Clause.new([Pattern.constructor(:succ, [Pattern.var(:pred)])], fn ctx ->
        succ(ctx.ih)
      end)
    ]
  end

  defp nat_matcher(name) do
    MatcherInfo.new(:"#{name}.match_1", 0, 1, [
      %Alternative{constructor: :zero, num_fields: 0},
      %Alternative{constructor: :succ, num_fields: 1}
    ])
  end

  defp nat, do: Term.const(:Nat)
  defp succ(term), do: Term.app(Term.const(:succ), term)
  defp nat_lam(name, body), do: Definition.unary(name, nat(), body)
end
