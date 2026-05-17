defmodule Theoria.Equation do
  @moduledoc """
  Small internal helpers for compiling constructor equations to recursor terms.

  This is deliberately not a surface equation compiler yet. It centralizes the
  core recursor shapes used by library definitions so later equation syntax can
  target one implementation path.
  """

  alias Theoria.Term

  @doc "Builds a Bool recursor application from the two constructor equations."
  @spec bool(Term.t(), Term.t(), Term.t(), Term.t()) :: Term.t()
  def bool(motive, on_true, on_false, major) do
    Term.const(:bool_rec)
    |> Term.app(motive)
    |> Term.app(on_true)
    |> Term.app(on_false)
    |> Term.app(major)
  end

  @doc "Builds a Nat recursor application from zero/succ equations."
  @spec nat(Term.t(), Term.t(), Term.t(), Term.t()) :: Term.t()
  def nat(motive, zero_case, succ_case, major) do
    Term.const(:nat_rec)
    |> Term.app(motive)
    |> Term.app(zero_case)
    |> Term.app(succ_case)
    |> Term.app(major)
  end

  @doc "Builds a List recursor application from nil/cons equations."
  @spec list(Term.t(), Term.t(), Term.t(), Term.t(), Term.t()) :: Term.t()
  def list(element_type, motive, nil_case, cons_case, major) do
    Term.const(:list_rec)
    |> Term.app(element_type)
    |> Term.app(motive)
    |> Term.app(nil_case)
    |> Term.app(cons_case)
    |> Term.app(major)
  end
end
