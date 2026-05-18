defmodule Theoria.Equation.Recursor.Application do
  @moduledoc "Experimental/internal API for 0.2; subject to change before 0.3. Internal raw recursor application builders used by the equation compiler."

  alias Theoria.Level
  alias Theoria.Term

  @doc "Builds a recursor application from a recursor name and positional arguments."
  @spec build(atom(), [Term.t()]) :: {:ok, Term.t()} | {:error, term()}
  def build(:bool_rec, [motive, on_true, on_false, major]),
    do: {:ok, bool_rec(motive, on_true, on_false, major)}

  def build(:nat_rec, [motive, zero_case, succ_case, major]),
    do: {:ok, nat_rec(motive, zero_case, succ_case, major)}

  def build(:list_rec, [element_type, motive, nil_case, cons_case, major]),
    do: {:ok, list_rec(element_type, motive, nil_case, cons_case, major)}

  def build(recursor, arguments),
    do: {:error, {:unsupported_recursor_application, recursor, length(arguments)}}

  @doc "Builds a Bool recursor application from the two constructor equations."
  @spec bool_rec(Term.t(), Term.t(), Term.t(), Term.t()) :: Term.t()
  def bool_rec(motive, on_true, on_false, major) do
    Term.const(:bool_rec, [1])
    |> Term.app(motive)
    |> Term.app(on_true)
    |> Term.app(on_false)
    |> Term.app(major)
  end

  @doc "Builds a Nat recursor application from zero/succ equations."
  @spec nat_rec(Term.t(), Term.t(), Term.t(), Term.t()) :: Term.t()
  def nat_rec(motive, zero_case, succ_case, major) do
    Term.const(:nat_rec, [1])
    |> Term.app(motive)
    |> Term.app(zero_case)
    |> Term.app(succ_case)
    |> Term.app(major)
  end

  @doc "Builds a List recursor application from nil/cons equations."
  @spec list_rec(Term.t(), Term.t(), Term.t(), Term.t(), Term.t(), [Level.t() | non_neg_integer()]) ::
          Term.t()
  def list_rec(element_type, motive, nil_case, cons_case, major, levels \\ [1, 1]) do
    Term.const(:list_rec, levels)
    |> Term.app(element_type)
    |> Term.app(motive)
    |> Term.app(nil_case)
    |> Term.app(cons_case)
    |> Term.app(major)
  end
end
