defmodule Theoria.Equation.Matcher.Statement do
  @moduledoc "Experimental/internal API for 0.2; subject to change before 0.3. Statement planning for matcher equations."

  alias Theoria.Equation.Lemma
  alias Theoria.Equation.Matcher.Equation, as: MatcherEquation
  alias Theoria.Equation.Matcher.Statement.Dispatch
  alias Theoria.Term

  @doc "Builds an indexed matcher equation theorem statement."
  @spec indexed(term(), MatcherEquation.t()) :: {:ok, Term.t()} | {:error, term()}
  def indexed(shape, %MatcherEquation{} = equation) do
    case find_alternative(shape, equation.constructor) do
      nil -> {:error, {:unknown_indexed_matcher_statement_constructor, equation.constructor}}
      alternative -> indexed_for_alternative(shape, equation, alternative)
    end
  end

  @doc "Turns planned indexed matcher equation statement metadata into lemma metadata."
  @spec indexed_to_lemma(MatcherEquation.t()) :: {:ok, Lemma.t()} | {:error, term()}
  def indexed_to_lemma(%MatcherEquation{indexed?: false, name: name}),
    do: {:error, {:not_indexed_matcher_statement, name}}

  def indexed_to_lemma(%MatcherEquation{statement_type: nil, name: name}),
    do: {:error, {:missing_indexed_matcher_statement, name}}

  def indexed_to_lemma(%MatcherEquation{} = equation) do
    {:ok,
     Lemma.new(equation.identity, equation.left, equation.right,
       equality_type: equation.statement_type
     )}
  end

  @doc "Builds indexed matcher equation statements for every equation."
  @spec indexed_all(term(), [MatcherEquation.t()]) ::
          {:ok, [MatcherEquation.t()]} | {:error, term()}
  def indexed_all(shape, equations) do
    Enum.reduce_while(equations, {:ok, []}, fn equation, {:ok, statements} ->
      case indexed(shape, equation) do
        {:ok, statement} ->
          {:cont,
           {:ok,
            [%{equation | statement_type: statement, statement_status: :planned} | statements]}}

        {:error, _reason} = error ->
          {:halt, error}
      end
    end)
    |> case do
      {:ok, statements} -> {:ok, Enum.reverse(statements)}
      {:error, _reason} = error -> error
    end
  end

  defp indexed_for_alternative(shape, %MatcherEquation{} = equation, alternative),
    do: Dispatch.indexed(shape, equation, alternative)

  defp find_alternative(shape, constructor),
    do: Enum.find(shape.alternatives, &(&1.constructor == constructor))
end
