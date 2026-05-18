defmodule Theoria.Equation.Matcher.Statement do
  @moduledoc "Experimental/internal API for 0.2; subject to change before 0.3. Statement planning for matcher equations."

  alias Theoria.Equation.Matcher.Equation, as: MatcherEquation
  alias Theoria.Equation.Matcher.Statement.Frame
  alias Theoria.Term

  @doc "Builds an indexed matcher equation theorem statement."
  @spec indexed(term(), MatcherEquation.t()) :: {:ok, Term.t()} | {:error, term()}
  def indexed(shape, %MatcherEquation{} = equation) do
    case find_alternative(shape, equation.constructor) do
      nil -> {:error, {:unknown_indexed_matcher_statement_constructor, equation.constructor}}
      alternative -> indexed_for_alternative(shape, equation, alternative)
    end
  end

  @doc "Builds indexed matcher equation statements for every equation."
  @spec indexed_all(term(), [MatcherEquation.t()]) ::
          {:ok, [MatcherEquation.t()]} | {:error, term()}
  def indexed_all(shape, equations) do
    Enum.reduce_while(equations, {:ok, []}, fn equation, {:ok, statements} ->
      case indexed(shape, equation) do
        {:ok, statement} -> {:cont, {:ok, [%{equation | statement_type: statement} | statements]}}
        {:error, _reason} = error -> {:halt, error}
      end
    end)
    |> case do
      {:ok, statements} -> {:ok, Enum.reverse(statements)}
      {:error, _reason} = error -> error
    end
  end

  defp indexed_for_alternative(
         %{family: :Vec} = shape,
         %MatcherEquation{constructor: :vec_nil} = equation,
         alternative
       ) do
    frame = base_frame(shape)
    index = hd(alternative.index_patterns)

    with {:ok, major} <- constructor_application(shape, alternative, frame),
         {:ok, motive} <- Frame.ref(frame, shape.motive_name),
         {:ok, lhs} <- matcher_application(shape, equation.matcher, frame, [index, major]),
         {:ok, rhs} <- Frame.ref(frame, alternative.binder_name) do
      result_type = motive |> Term.app(index) |> Term.app(major)
      {:ok, Frame.forall(frame, Term.eq(result_type, lhs, rhs))}
    end
  end

  defp indexed_for_alternative(
         %{family: :Vec} = shape,
         %MatcherEquation{constructor: :vec_cons} = equation,
         alternative
       ) do
    base = base_frame(shape)
    index = hd(alternative.index_patterns)

    with {:ok, field_binders} <- constructor_field_binders(shape, alternative, base) do
      frame = Frame.push_many(base, field_binders)

      with {:ok, major} <- constructor_application(shape, alternative, frame),
           {:ok, motive} <- Frame.ref(frame, shape.motive_name),
           {:ok, lhs} <- matcher_application(shape, equation.matcher, frame, [index, major]),
           {:ok, rhs} <- alternative_application(shape, equation.matcher, frame, alternative) do
        result_type = motive |> Term.app(index) |> Term.app(major)
        {:ok, Frame.forall(frame, Term.eq(result_type, lhs, rhs))}
      end
    end
  end

  defp indexed_for_alternative(shape, %MatcherEquation{} = equation, _alternative),
    do: {:error, {:unsupported_indexed_matcher_statement, shape.family, equation.constructor}}

  defp base_frame(shape), do: Frame.new(statement_binders(shape))

  defp statement_binders(shape),
    do:
      shape.parameters ++
        [{shape.motive_name, shape.motive_type}] ++
        shape.index_binders ++ shape.discriminant_binders ++ shape.alternative_binders

  defp constructor_field_binders(%{family: :Vec}, alternative, frame) do
    names =
      alternative
      |> case_binders()
      |> Enum.take(length(alternative.fields))
      |> Enum.map(&elem(&1, 0))

    alternative.fields
    |> Enum.zip(names)
    |> Enum.reduce_while({:ok, {[], frame}}, fn {field, name}, {:ok, {binders, current_frame}} ->
      case vec_field_type(field, current_frame) do
        {:ok, type} ->
          {:cont, {:ok, {[{name, type} | binders], Frame.push(current_frame, name, type)}}}

        {:error, _reason} = error ->
          {:halt, error}
      end
    end)
    |> case do
      {:ok, {binders, _frame}} -> {:ok, Enum.reverse(binders)}
      {:error, _reason} = error -> error
    end
  end

  defp vec_field_type(%{position: 0}, frame), do: Frame.ref(frame, :a)
  defp vec_field_type(%{position: 1}, _frame), do: {:ok, Term.const(:Nat)}

  defp vec_field_type(%{position: 2}, frame) do
    with {:ok, a} <- Frame.ref(frame, :a),
         {:ok, n} <- Frame.ref(frame, :n) do
      {:ok, Term.const(:Vec, [1]) |> Term.app(a) |> Term.app(n)}
    end
  end

  defp constructor_application(shape, alternative, frame) do
    with {:ok, parameters} <- refs_for_names(frame, Keyword.keys(shape.parameters)),
         {:ok, fields} <- field_refs(alternative, frame) do
      arguments = parameters ++ fields

      {:ok,
       Enum.reduce(arguments, Term.const(alternative.constructor, [1]), fn argument, term ->
         Term.app(term, argument)
       end)}
    end
  end

  defp alternative_application(%{family: :Vec} = shape, matcher, frame, alternative) do
    with {:ok, fields} <- field_refs(alternative, frame),
         {:ok, ihs} <- recursive_hypotheses(shape, matcher, frame, alternative),
         {:ok, alternative_ref} <- Frame.ref(frame, alternative.binder_name) do
      {:ok,
       Enum.reduce(fields ++ ihs, alternative_ref, fn argument, term ->
         Term.app(term, argument)
       end)}
    end
  end

  defp recursive_hypotheses(%{family: :Vec} = shape, matcher, frame, alternative) do
    alternative.fields
    |> Enum.filter(& &1.recursive?)
    |> Enum.reduce_while({:ok, []}, fn _field, {:ok, hypotheses} ->
      with {:ok, n} <- Frame.ref(frame, :n),
           {:ok, arg2} <- Frame.ref(frame, :arg2),
           {:ok, hypothesis} <- matcher_application(shape, matcher, frame, [n, arg2]) do
        {:cont, {:ok, [hypothesis | hypotheses]}}
      else
        {:error, _reason} = error -> {:halt, error}
      end
    end)
    |> case do
      {:ok, hypotheses} -> {:ok, Enum.reverse(hypotheses)}
      {:error, _reason} = error -> error
    end
  end

  defp field_refs(alternative, frame) do
    alternative
    |> case_binders()
    |> Enum.take(length(alternative.fields))
    |> Enum.map(&elem(&1, 0))
    |> then(&refs_for_names(frame, &1))
  end

  defp matcher_application(shape, matcher, frame, [index, major]) do
    with {:ok, parameters} <- refs_for_names(frame, Keyword.keys(shape.parameters)),
         {:ok, motive} <- Frame.ref(frame, shape.motive_name),
         {:ok, alternatives} <- alternative_refs(shape, frame) do
      arguments = parameters ++ [motive, index, major] ++ alternatives

      {:ok,
       Enum.reduce(arguments, Term.const(matcher, [1]), fn argument, term ->
         Term.app(term, argument)
       end)}
    end
  end

  defp alternative_refs(shape, frame) do
    refs_for_names(frame, Enum.map(shape.alternatives, & &1.binder_name))
  end

  defp refs_for_names(frame, names) do
    Enum.reduce_while(names, {:ok, []}, fn name, {:ok, refs} ->
      case Frame.ref(frame, name) do
        {:ok, ref} -> {:cont, {:ok, [ref | refs]}}
        {:error, _reason} = error -> {:halt, error}
      end
    end)
    |> case do
      {:ok, refs} -> {:ok, Enum.reverse(refs)}
      {:error, _reason} = error -> error
    end
  end

  defp case_binders(alternative), do: collect_foralls(alternative.binder_type)

  defp collect_foralls(%Term.Forall{name: name, domain: domain, body: body}) do
    [{name, domain} | collect_foralls(body)]
  end

  defp collect_foralls(_body), do: []

  defp find_alternative(shape, constructor),
    do: Enum.find(shape.alternatives, &(&1.constructor == constructor))
end
