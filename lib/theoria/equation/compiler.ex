defmodule Theoria.Equation.Compiler do
  @moduledoc "Constructor-equation compiler for the initial Bool/Nat/List fragment."

  alias Theoria.Equation.Clause
  alias Theoria.Equation.Pattern.{Constructor, Var, Wildcard}
  alias Theoria.Equation.Recursors
  alias Theoria.Level
  alias Theoria.Term

  @type result :: {:ok, Term.t()} | {:error, term()}

  @doc "Compiles Bool constructor clauses to a Bool recursor application."
  @spec compile_bool(Term.t(), [Clause.t()], Term.t()) :: result()
  def compile_bool(motive, clauses, major) do
    expected = %{true => 0, false => 0}

    with :ok <- validate_clauses(clauses, expected),
         {:ok, on_true} <- constructor_body(clauses, true),
         {:ok, on_false} <- constructor_body(clauses, false) do
      {:ok, Recursors.bool(motive, on_true, on_false, major)}
    end
  end

  @doc "Compiles Nat zero/succ clauses to a Nat recursor application."
  @spec compile_nat(Term.t(), [Clause.t()], Term.t()) :: result()
  def compile_nat(motive, clauses, major) do
    expected = %{zero: 0, succ: 1}

    with :ok <- validate_clauses(clauses, expected),
         {:ok, zero_case} <- constructor_body(clauses, :zero),
         {:ok, succ_case} <- constructor_body(clauses, :succ) do
      {:ok, Recursors.nat(motive, zero_case, materialize_nat_succ(succ_case), major)}
    end
  end

  @doc "Compiles List nil/cons clauses to a List recursor application."
  @spec compile_list(Term.t(), Term.t(), [Clause.t()], Term.t(), [Level.t() | non_neg_integer()]) ::
          result()
  def compile_list(element_type, motive, clauses, major, levels \\ [1, 1]) do
    expected = %{list_nil: 0, list_cons: 2}

    with :ok <- validate_clauses(clauses, expected),
         {:ok, nil_case} <- constructor_body(clauses, :list_nil),
         {:ok, cons_case} <- constructor_body(clauses, :list_cons) do
      {:ok,
       Recursors.list(
         element_type,
         motive,
         nil_case,
         materialize_list_cons(cons_case, element_type),
         major,
         levels
       )}
    end
  end

  defp validate_clauses(clauses, expected) do
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

  defp arity_mismatch?(args, expected, name), do: length(args) != Map.fetch!(expected, name)

  defp validate_coverage(seen, expected) do
    expected
    |> Map.keys()
    |> Enum.find(&(&1 not in seen))
    |> case do
      nil -> :ok
      missing -> {:error, {:missing_clause, missing}}
    end
  end

  defp constructor_body(clauses, constructor) do
    clauses
    |> Enum.find(&constructor_clause?(&1, constructor))
    |> case do
      %Clause{body: body} = clause -> {:ok, materialize_clause(clause, body)}
      nil -> {:error, {:missing_clause, constructor}}
    end
  end

  defp constructor_clause?(%Clause{patterns: [%Constructor{name: name}]}, name), do: true
  defp constructor_clause?(_clause, _constructor), do: false

  defp materialize_clause(%Clause{binders: []}, body), do: body
  defp materialize_clause(%Clause{binders: binders}, body), do: wrap_lambdas(binders, body)

  defp materialize_nat_succ(%Term.Lam{} = body), do: body

  defp materialize_nat_succ(body),
    do: wrap_lambdas([pred: Term.const(:Nat), ih: Term.const(:Nat)], body)

  defp materialize_list_cons(%Term.Lam{} = body, _element_type), do: body

  defp materialize_list_cons(body, element_type) do
    list_type = Term.app(Term.const(:List, [Level.param(:u)]), Term.shift(element_type, 1))

    wrap_lambdas(
      [head: element_type, tail: list_type, ih: list_type],
      body
    )
  end

  defp wrap_lambdas(binders, body) do
    Enum.reduce(binders, body, fn {name, type}, body -> Term.lam(name, type, body) end)
  end
end
