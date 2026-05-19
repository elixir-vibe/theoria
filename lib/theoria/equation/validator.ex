defmodule Theoria.Equation.Validator do
  @moduledoc "Experimental before 1.0; the shape may change. Validation for constructor-equation clauses."

  alias Theoria.Equation.Clause
  alias Theoria.Equation.Pattern.{Constructor, Var, Wildcard}

  @doc "Validates clause coverage and pattern shape for expected constructors."
  @spec validate_clauses([Clause.t()], %{required(atom()) => non_neg_integer()}) ::
          :ok | {:error, term()}
  def validate_clauses(clauses, expected) do
    Enum.reduce_while(clauses, MapSet.new(), &validate_clause(&1, &2, expected))
    |> case do
      {:error, _reason} = error -> error
      seen -> validate_coverage(seen, expected)
    end
  end

  defp validate_clause(%Clause{patterns: [%Constructor{name: name, args: args}]}, seen, expected) do
    cond do
      not Map.has_key?(expected, name) ->
        {:halt, {:error, {:unexpected_clause, name}}}

      MapSet.member?(seen, name) ->
        {:halt, {:error, {:duplicate_clause, name}}}

      arity_mismatch?(args, expected, name) ->
        expected_arity = Map.fetch!(expected, name)
        actual_arity = length(args)

        {:halt,
         {:error,
          {:constructor_arity_mismatch, name, [expected: expected_arity, actual: actual_arity]}}}

      true ->
        case validate_patterns(args, MapSet.new()) do
          :ok -> {:cont, MapSet.put(seen, name)}
          {:error, reason} -> {:halt, {:error, reason}}
        end
    end
  end

  defp validate_clause(_clause, _seen, _expected), do: {:halt, {:error, :invalid_clause}}

  defp arity_mismatch?(args, expected, name), do: length(args) != Map.fetch!(expected, name)

  defp validate_patterns(patterns, seen) do
    patterns
    |> validate_pattern_list(seen)
    |> case do
      {:ok, _seen} -> :ok
      {:error, _reason} = error -> error
    end
  end

  defp validate_pattern(%Wildcard{}, seen), do: {:ok, seen}

  defp validate_pattern(%Var{name: name}, seen) do
    if MapSet.member?(seen, name) do
      {:error, {:duplicate_pattern_variable, name}}
    else
      {:ok, MapSet.put(seen, name)}
    end
  end

  defp validate_pattern(%Constructor{args: args}, seen), do: validate_pattern_list(args, seen)
  defp validate_pattern(other, _seen), do: {:error, {:invalid_pattern, other}}

  defp validate_pattern_list(patterns, seen) do
    Enum.reduce_while(patterns, {:ok, seen}, fn pattern, {:ok, seen} ->
      case validate_pattern(pattern, seen) do
        {:ok, seen} -> {:cont, {:ok, seen}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp validate_coverage(seen, expected) do
    expected
    |> Map.keys()
    |> Enum.find(&(&1 not in seen))
    |> case do
      nil -> :ok
      missing -> {:error, {:missing_clause, missing}}
    end
  end
end
