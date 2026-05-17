defmodule Theoria.Library.List do
  @moduledoc """
  Initial polymorphic list declarations and primitive recursion.
  """

  alias Theoria.Env
  alias Theoria.Equation
  alias Theoria.Equation.{Clause, Pattern}
  alias Theoria.Inductive.Generate
  alias Theoria.Inductive.Spec
  alias Theoria.Kernel
  alias Theoria.Level
  alias Theoria.Library.Nat
  alias Theoria.Term

  import Theoria.DSL, except: [type: 1]

  @doc "Extends an environment with list declarations. Requires Nat declarations."
  def extend(%Env{} = env) do
    with {:ok, env} <- Kernel.add_inductive(env, inductive_spec()),
         {:ok, env} <-
           Kernel.add_definition(env, :list_length, list_length_type(), list_length_value(), [:u]) do
      Kernel.add_definition(env, :list_append, list_append_type(), list_append_value(), [:u])
    end
  end

  @doc "Returns a new Nat environment extended with list declarations."
  def env do
    with {:ok, env} <- Nat.env() do
      extend(env)
    end
  end

  @doc "Returns the inductive specification described by this library."
  def inductive_spec do
    spec =
      :List
      |> Spec.new(list_type(), universe_params: [:u, :v])
      |> Spec.parameter(:a, term(do: sort(u)) |> elab!())
      |> Spec.constructor(:list_nil, list_nil_type())
      |> Spec.constructor(:list_cons, list_cons_type())

    %Spec{spec | recursors: Generate.eliminators!(spec)}
  end

  defp list_type do
    u = Level.param(:u)
    sort_u = Theoria.Syntax.sort(u)

    elab!(
      forall :a, sort_u do
        sort_u
      end
    )
  end

  defp list_nil_type do
    u = Level.param(:u)

    elab!(
      forall :a, Theoria.Syntax.sort(u) do
        call(const(:List, [u]), var(:a))
      end
    )
  end

  defp list_cons_type do
    u = Level.param(:u)
    a = var(:a)
    list_a = call(const(:List, [u]), a)

    elab!(
      forall :a, Theoria.Syntax.sort(u) do
        arrow(a, arrow(list_a, list_a))
      end
    )
  end

  defp list_length_type do
    u = Level.param(:u)

    elab!(
      forall :a, Theoria.Syntax.sort(u) do
        arrow(call(const(:List, [u]), var(:a)), const(:Nat))
      end
    )
  end

  defp list_append_type do
    u = Level.param(:u)
    a = var(:a)
    list_a = call(const(:List, [u]), a)

    elab!(
      forall :a, Theoria.Syntax.sort(u) do
        arrow(list_a, arrow(list_a, list_a))
      end
    )
  end

  defp list_append_value do
    u = Level.param(:u)
    a = Term.bvar(2)
    list_a = list_of(a)

    {:ok, body} =
      Equation.compile_list(
        a,
        list_a,
        [
          Clause.new([Pattern.constructor(:list_nil)], Term.bvar(0)),
          Clause.new(
            [Pattern.constructor(:list_cons, [Pattern.var(:head), Pattern.var(:tail)])],
            list_cons_branch()
          )
        ],
        Term.bvar(1),
        [u, u]
      )

    sort_u = Term.sort(u)
    bound_a = Term.bvar(0)
    outer_list = list_of(bound_a)

    Term.lam(
      :a,
      sort_u,
      Term.lam(
        :left,
        outer_list,
        Term.lam(:right, list_of(Term.shift(bound_a, 1)), body)
      )
    )
  end

  defp list_length_value do
    u = Level.param(:u)
    xs = Term.bvar(0)
    element_type = Term.bvar(1)

    {:ok, body} =
      Equation.compile_list(
        element_type,
        Term.const(:Nat),
        [
          Clause.new([Pattern.constructor(:list_nil)], Term.const(:zero)),
          Clause.new(
            [Pattern.constructor(:list_cons, [Pattern.wildcard(), Pattern.var(:tail)])],
            Term.app(Term.const(:succ), branch_ih())
          )
        ],
        xs,
        [u, 1]
      )

    sort_u = Term.sort(u)
    bound_a = Term.bvar(0)

    Term.lam(
      :a,
      sort_u,
      Term.lam(:xs, list_of(bound_a), body)
    )
  end

  defp branch_ih, do: Term.bvar(0)

  defp list_cons_branch do
    Term.const(:list_cons, [Level.param(:u)])
    |> Term.app(Term.bvar(5))
    |> Term.app(Term.bvar(2))
    |> Term.app(Term.bvar(0))
  end

  defp list_of(type) do
    Term.app(Term.const(:List, [Level.param(:u)]), type)
  end
end
