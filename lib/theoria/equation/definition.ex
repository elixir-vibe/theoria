defmodule Theoria.Equation.Definition do
  @moduledoc "Experimental/internal API for 0.2; subject to change before 0.3. Small internal helpers for building core lambda definitions."

  alias Theoria.Term

  @type binder :: {atom(), Term.t()}

  @doc "Wraps a body in multiple lambdas."
  @spec lam_many([binder()], Term.t()) :: Term.t()
  def lam_many(binders, body) do
    binders
    |> Enum.reverse()
    |> Enum.reduce(body, fn {name, type}, body -> Term.lam(name, type, body) end)
  end

  @doc "Builds a unary core lambda."
  @spec unary(atom(), Term.t(), Term.t()) :: Term.t()
  def unary(name, type, body), do: lam_many([{name, type}], body)

  @doc "Builds a binary core lambda."
  @spec binary(atom(), Term.t(), atom(), Term.t(), Term.t()) :: Term.t()
  def binary(left_name, left_type, right_name, right_type, body) do
    lam_many([{left_name, left_type}, {right_name, right_type}], body)
  end
end
