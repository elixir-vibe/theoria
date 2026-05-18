defmodule Theoria.Library.Nat do
  @moduledoc """
  Initial natural number declarations and primitive recursion.
  """

  alias Theoria.Env
  alias Theoria.Equation
  alias Theoria.Equation.Case.Template, as: CaseTemplate
  alias Theoria.Equation.Definition.Spec, as: DefinitionSpec

  alias Theoria.Equation.{
    Clause,
    Definition,
    Pattern,
    Signature
  }

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

      with {:ok, compiled} <-
             Equation.compile_definition(
               :nat,
               nat_add_signature(),
               nat(),
               nat_add_clauses(),
               Term.bvar(1),
               cases: nat_add_cases()
             ),
           {:ok, spec} <-
             DefinitionSpec.from_compiled(:nat_add, type, value, compiled) do
        DefinitionSpec.add_to_env(env, spec)
      end
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

  defp nat_add_signature do
    Signature.new(:nat_add, :nat, [{:m, nat()}, {:n, nat()}], nat(), rec_arg_pos: 0)
  end

  defp nat_add_cases do
    n = Term.bvar(0)
    m = Term.bvar(1)

    [
      CaseTemplate.new(:zero, app(:nat_add, zero(), n), n, binders: [{:n, nat()}]),
      CaseTemplate.new(
        :succ,
        app(:nat_add, succ(m), n),
        succ(app(:nat_add, m, n)),
        binders: [{:m, nat()}, {:n, nat()}]
      )
    ]
  end

  defp app(name, arg1, arg2), do: Term.const(name) |> Term.app(arg1) |> Term.app(arg2)
  defp nat, do: Term.const(:Nat)
  defp zero, do: Term.const(:zero)
  defp succ(term), do: Term.app(Term.const(:succ), term)
  defp nat_lam(name, body), do: Definition.unary(name, nat(), body)
end
