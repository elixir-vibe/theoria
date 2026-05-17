defmodule Theoria.Equation.Recursors do
  @moduledoc "Raw recursor application builders used by the equation compiler."

  alias Theoria.Level
  alias Theoria.Term

  @doc "Builds a Bool recursor application from the two constructor equations."
  @spec bool(Term.t(), Term.t(), Term.t(), Term.t()) :: Term.t()
  def bool(motive, on_true, on_false, major) do
    Term.const(:bool_rec, [1])
    |> Term.app(motive)
    |> Term.app(on_true)
    |> Term.app(on_false)
    |> Term.app(major)
  end

  @doc "Builds a Nat recursor application from zero/succ equations."
  @spec nat(Term.t(), Term.t(), Term.t(), Term.t()) :: Term.t()
  def nat(motive, zero_case, succ_case, major) do
    Term.const(:nat_rec, [1])
    |> Term.app(motive)
    |> Term.app(zero_case)
    |> Term.app(succ_case)
    |> Term.app(major)
  end

  @doc "Builds a List recursor application from nil/cons equations."
  @spec list(Term.t(), Term.t(), Term.t(), Term.t(), Term.t(), [Level.t() | non_neg_integer()]) ::
          Term.t()
  def list(element_type, motive, nil_case, cons_case, major, levels \\ [1, 1]) do
    Term.const(:list_rec, levels)
    |> Term.app(element_type)
    |> Term.app(motive)
    |> Term.app(nil_case)
    |> Term.app(cons_case)
    |> Term.app(major)
  end
end
