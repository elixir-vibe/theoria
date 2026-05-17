defmodule Theoria.Library.Bool do
  @moduledoc """
  Initial computational boolean declarations.

  This library introduces booleans as ordinary data in `Type 0`, distinct from
  the logical propositions `True` and `False` in `Theoria.Library.Logic`.
  """

  alias Theoria.Env
  alias Theoria.Equation
  alias Theoria.Equation.{Clause, Context, Definition, Pattern}
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
        [
          Clause.new([Pattern.constructor(true)], bool_false()),
          Clause.new([Pattern.constructor(false)], bool_true())
        ],
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
        [
          Clause.new([Pattern.constructor(true)], fn ctx -> ctx.b end),
          Clause.new([Pattern.constructor(false)], bool_false())
        ],
        Term.bvar(1),
        Context.new(%{}, %{b: Term.bvar(0)})
      )

    Definition.binary(:a, bool(), :b, bool(), body)
  end

  defp bool_or_value do
    {:ok, body} =
      Equation.compile_bool(
        bool(),
        [
          Clause.new([Pattern.constructor(true)], bool_true()),
          Clause.new([Pattern.constructor(false)], fn ctx -> ctx.b end)
        ],
        Term.bvar(1),
        Context.new(%{}, %{b: Term.bvar(0)})
      )

    Definition.binary(:a, bool(), :b, bool(), body)
  end

  defp bool, do: Term.const(:Bool)
  defp bool_true, do: Term.const(true)
  defp bool_false, do: Term.const(false)
  defp bool_lam(name, body), do: Definition.unary(name, bool(), body)
end
