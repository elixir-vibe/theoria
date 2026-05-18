defmodule Theoria.Equation.Branch do
  @moduledoc "Experimental/internal API for 0.2; subject to change before 0.3. Internal constructor-specific branch descriptors for equation compilation."

  alias Theoria.Env.RecursorRule
  alias Theoria.Equation.Clause
  alias Theoria.Equation.Context
  alias Theoria.Equation.Pattern.{Constructor, Var}
  alias Theoria.Level
  alias Theoria.Term

  @enforce_keys [:binders, :context]
  defstruct [:binders, :context]

  @type binder :: {atom(), Term.t()}
  @type t :: %__MODULE__{binders: [binder()], context: Context.t()}

  @doc "Builds the Nat successor branch descriptor."
  @spec nat_succ(Clause.t()) :: t()
  def nat_succ(%Clause{} = clause) do
    binders = [{branch_name(clause, 0, :pred), Term.const(:Nat)}, {:ih, Term.const(:Nat)}]
    new(binders)
  end

  @doc "Builds the List cons branch descriptor."
  @spec list_cons(Clause.t(), Term.t(), Term.t()) :: t()
  def list_cons(%Clause{} = clause, element_type, motive) do
    head_name = branch_name(clause, 0, :head)
    tail_name = branch_name(clause, 1, :tail)
    tail_type = Term.app(Term.const(:List, [Level.param(:u)]), Term.shift(element_type, 1))
    ih_type = Term.shift(motive, 2)
    binders = [{head_name, element_type}, {tail_name, tail_type}, {:ih, ih_type}]
    outer = %{a: Term.shift(element_type, 3), element_type: Term.shift(element_type, 3)}

    new(binders, outer)
  end

  @doc "Builds a generic branch descriptor from recursor-rule metadata."
  @spec from_recursor_rule(Clause.t(), RecursorRule.t(), [Term.t()], map()) :: t()
  def from_recursor_rule(%Clause{} = clause, %RecursorRule{} = rule, field_types, outer \\ %{}) do
    binders =
      field_types
      |> Enum.take(rule.field_count)
      |> Enum.with_index()
      |> Enum.map(fn {type, index} -> {branch_name(clause, index, :"field#{index}"), type} end)

    new(binders, outer)
  end

  @doc "Builds a Vec cons branch metadata descriptor for indexed-equation planning."
  @spec vec_cons(Clause.t(), Term.t(), Term.t(), Term.t()) :: t()
  def vec_cons(%Clause{} = clause, element_type, length_index, motive) do
    n_name = branch_name(clause, 0, :n)
    head_name = branch_name(clause, 1, :head)
    tail_name = branch_name(clause, 2, :tail)
    vec_tail = Term.const(:Vec) |> Term.app(Term.shift(element_type, 2)) |> Term.app(Term.bvar(1))
    ih_type = Term.shift(motive, 3)

    binders = [
      {n_name, Term.const(:Nat)},
      {head_name, element_type},
      {tail_name, vec_tail},
      {:ih, ih_type}
    ]

    outer = %{
      a: Term.shift(element_type, 4),
      element_type: Term.shift(element_type, 4),
      length: Term.shift(length_index, 4)
    }

    new(binders, outer)
  end

  @doc "Wraps a body in the branch binders."
  @spec wrap(t(), Term.t()) :: Term.t()
  def wrap(%__MODULE__{binders: binders}, body) do
    binders
    |> Enum.reverse()
    |> Enum.reduce(body, fn {name, type}, body -> Term.lam(name, type, body) end)
  end

  defp new(binders, outer \\ %{}) do
    %__MODULE__{binders: binders, context: Context.new(branch_vars(binders), outer)}
  end

  defp branch_vars(binders) do
    binders
    |> Enum.map(&elem(&1, 0))
    |> Enum.reverse()
    |> Enum.with_index()
    |> Map.new(fn {name, index} -> {name, Term.bvar(index)} end)
  end

  defp branch_name(%Clause{patterns: [%Constructor{args: args}]}, index, fallback) do
    case Enum.at(args, index) do
      %Var{name: name} -> name
      _pattern -> fallback
    end
  end
end
