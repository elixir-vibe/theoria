defmodule Theoria.Equation.Matcher.Statement.Dispatch do
  @moduledoc "Dispatches indexed matcher equation statement planning to family-specific planners."

  alias Theoria.Equation.Matcher.Equation, as: MatcherEquation
  alias Theoria.Equation.Matcher.Statement.Vec, as: VecStatement

  @doc "Builds an indexed matcher statement with the planner registered for the shape family."
  @spec indexed(term(), MatcherEquation.t(), term()) :: {:ok, Theoria.Term.t()} | {:error, term()}
  def indexed(%{family: :Vec} = shape, %MatcherEquation{} = equation, alternative),
    do: VecStatement.indexed(shape, equation, alternative)

  def indexed(shape, %MatcherEquation{} = equation, _alternative),
    do: {:error, {:unsupported_indexed_matcher_statement, shape.family, equation.constructor}}
end
