defmodule Theoria.Library.Bool do
  @moduledoc """
  Initial computational boolean declarations.

  This library introduces booleans as ordinary data in `Type 0`, distinct from
  the logical propositions `True` and `False` in `Theoria.Library.Logic`.
  """

  alias Theoria.Env
  alias Theoria.Equation

  alias Theoria.Equation.{
    CaseTemplate,
    Clause,
    Context,
    Definition,
    DefinitionSpec,
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

  @doc "Extends an environment with boolean declarations."
  def extend(%Env{} = env) do
    with {:ok, env} <- Kernel.add_inductive(env, inductive_spec()),
         {:ok, env} <-
           add_equation_definition(env, :bool_not, bool_not_type(), bool_not_value(), 0,
             clauses: bool_not_clauses(),
             major: Term.bvar(0)
           ),
         {:ok, env} <-
           add_equation_definition(env, :bool_and, bool_binary_type(), bool_and_value(), 0,
             clauses: bool_and_clauses(),
             major: Term.bvar(1),
             context: Context.new(%{}, %{b: Term.bvar(0)})
           ) do
      add_equation_definition(env, :bool_or, bool_binary_type(), bool_or_value(), 0,
        clauses: bool_or_clauses(),
        major: Term.bvar(1),
        context: Context.new(%{}, %{b: Term.bvar(0)})
      )
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
      |> Spec.constructor(true, Term.const(:Bool))
      |> Spec.constructor(false, Term.const(:Bool))

    %Spec{spec | recursors: Generate.eliminators!(spec)}
  end

  defp bool_not_type do
    elab!(arrow(const(:Bool), const(:Bool)))
  end

  defp bool_not_value do
    {:ok, body} =
      Equation.compile_bool(
        bool(),
        bool_not_clauses(),
        Term.bvar(0)
      )

    bool_lam(:b, body)
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
    {:ok, body} =
      Equation.compile_bool(
        bool(),
        bool_and_clauses(),
        Term.bvar(1),
        Context.new(%{}, %{b: Term.bvar(0)})
      )

    Definition.binary(:a, bool(), :b, bool(), body)
  end

  defp bool_or_value do
    {:ok, body} =
      Equation.compile_bool(
        bool(),
        bool_or_clauses(),
        Term.bvar(1),
        Context.new(%{}, %{b: Term.bvar(0)})
      )

    Definition.binary(:a, bool(), :b, bool(), body)
  end

  defp add_equation_definition(env, name, type, value, rec_arg_pos, opts) do
    clauses = Keyword.fetch!(opts, :clauses)
    major = Keyword.fetch!(opts, :major)

    with {:ok, compiled} <-
           Equation.compile_definition(
             :bool,
             bool_signature(name, rec_arg_pos),
             bool(),
             clauses,
             major,
             cases: bool_cases(name),
             context: Keyword.get(opts, :context, Context.new())
           ),
         {:ok, spec} <- DefinitionSpec.from_compiled(name, type, value, compiled) do
      DefinitionSpec.add_to_env(env, spec)
    end
  end

  defp bool_not_clauses do
    [
      Clause.new([Pattern.constructor(true)], bool_false()),
      Clause.new([Pattern.constructor(false)], bool_true())
    ]
  end

  defp bool_and_clauses do
    [
      Clause.new([Pattern.constructor(true)], fn ctx -> ctx.b end),
      Clause.new([Pattern.constructor(false)], bool_false())
    ]
  end

  defp bool_or_clauses do
    [
      Clause.new([Pattern.constructor(true)], bool_true()),
      Clause.new([Pattern.constructor(false)], fn ctx -> ctx.b end)
    ]
  end

  defp bool_signature(:bool_not, rec_arg_pos) do
    Signature.new(:bool_not, :bool, [{:b, bool()}], bool(), rec_arg_pos: rec_arg_pos)
  end

  defp bool_signature(name, rec_arg_pos) when name in [:bool_and, :bool_or] do
    Signature.new(name, :bool, [{:a, bool()}, {:b, bool()}], bool(),
      rec_arg_pos: rec_arg_pos,
      discriminant_positions: [0, 1]
    )
  end

  defp bool_cases(:bool_not) do
    [
      CaseTemplate.new(true, bool_app(:bool_not, bool_true()), bool_false()),
      CaseTemplate.new(false, bool_app(:bool_not, bool_false()), bool_true())
    ]
  end

  defp bool_cases(:bool_and) do
    [
      CaseTemplate.new(:true_true, bool_app(:bool_and, bool_true(), bool_true()), bool_true()),
      CaseTemplate.new(:true_false, bool_app(:bool_and, bool_true(), bool_false()), bool_false()),
      CaseTemplate.new(:false_true, bool_app(:bool_and, bool_false(), bool_true()), bool_false()),
      CaseTemplate.new(
        :false_false,
        bool_app(:bool_and, bool_false(), bool_false()),
        bool_false()
      )
    ]
  end

  defp bool_cases(:bool_or) do
    [
      CaseTemplate.new(:true_true, bool_app(:bool_or, bool_true(), bool_true()), bool_true()),
      CaseTemplate.new(:true_false, bool_app(:bool_or, bool_true(), bool_false()), bool_true()),
      CaseTemplate.new(:false_true, bool_app(:bool_or, bool_false(), bool_true()), bool_true()),
      CaseTemplate.new(:false_false, bool_app(:bool_or, bool_false(), bool_false()), bool_false())
    ]
  end

  defp bool_app(name, arg), do: Term.app(Term.const(name), arg)
  defp bool_app(name, arg1, arg2), do: Term.const(name) |> Term.app(arg1) |> Term.app(arg2)

  defp bool, do: Term.const(:Bool)
  defp bool_true, do: Term.const(true)
  defp bool_false, do: Term.const(false)
  defp bool_lam(name, body), do: Definition.unary(name, bool(), body)
end
