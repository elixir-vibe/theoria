defmodule Theoria.Equation.Matcher.Statement.Vec do
  @moduledoc "Internal indexed Vec statement planner for matcher equations."

  alias Theoria.Equation.Matcher.Equation, as: MatcherEquation
  alias Theoria.Equation.Matcher.Statement.Frame
  alias Theoria.Equation.Matcher.Statement.Indexed
  alias Theoria.Term

  defmodule FieldBinder do
    @moduledoc false

    @enforce_keys [:field, :name, :type]
    defstruct [:field, :name, :type]
  end

  @spec indexed(term(), MatcherEquation.t(), term()) :: {:ok, Term.t()} | {:error, term()}
  def indexed(
        %{family: :Vec} = shape,
        %MatcherEquation{constructor: :vec_nil} = equation,
        alternative
      ) do
    frame = base_frame(shape)
    index = hd(alternative.index_patterns)
    field_binders = []

    with {:ok, major} <- constructor_application(shape, alternative, frame, field_binders),
         {:ok, motive} <- Frame.ref(frame, shape.motive_name),
         {:ok, lhs} <- matcher_application(shape, equation.matcher, frame, [index, major]),
         {:ok, rhs} <- Frame.ref(frame, alternative.binder_name) do
      result_type = motive |> Term.app(index) |> Term.app(major)
      {:ok, Frame.forall(frame, Term.eq(result_type, lhs, rhs))}
    end
  end

  def indexed(
        %{family: :Vec} = shape,
        %MatcherEquation{constructor: :vec_cons} = equation,
        alternative
      ) do
    base = base_frame(shape)

    with {:ok, field_binders} <- constructor_field_binders(shape, alternative, base) do
      frame = Frame.push_many(base, field_binder_pairs(field_binders))
      index = hd(alternative.index_patterns)

      with {:ok, major} <- constructor_application(shape, alternative, frame, field_binders),
           {:ok, motive} <- Frame.ref(frame, shape.motive_name),
           {:ok, lhs} <- matcher_application(shape, equation.matcher, frame, [index, major]),
           {:ok, rhs} <-
             alternative_application(shape, equation.matcher, frame, alternative, field_binders) do
        result_type = motive |> Term.app(index) |> Term.app(major)
        {:ok, Frame.forall(frame, Term.eq(result_type, lhs, rhs))}
      end
    end
  end

  def indexed(shape, %MatcherEquation{} = equation, _alternative),
    do: {:error, {:unsupported_indexed_matcher_statement, shape.family, equation.constructor}}

  defp base_frame(shape), do: Frame.new(Indexed.statement_binders(shape))

  defp constructor_field_binders(%{family: :Vec} = shape, alternative, frame) do
    names =
      alternative
      |> case_binders()
      |> Enum.take(length(alternative.fields))
      |> Enum.map(&elem(&1, 0))

    alternative.fields
    |> Enum.zip(names)
    |> Enum.reduce_while({:ok, {[], frame}}, fn {field, name}, {:ok, {binders, current_frame}} ->
      case vec_field_type(shape, field, current_frame) do
        {:ok, type} ->
          binder = %FieldBinder{field: field, name: name, type: type}
          {:cont, {:ok, {[binder | binders], Frame.push(current_frame, name, type)}}}

        {:error, _reason} = error ->
          {:halt, error}
      end
    end)
    |> case do
      {:ok, {binders, _frame}} -> {:ok, Enum.reverse(binders)}
      {:error, _reason} = error -> error
    end
  end

  defp vec_field_type(_shape, %{position: 0}, frame), do: Frame.ref(frame, :a)
  defp vec_field_type(_shape, %{position: 1}, _frame), do: {:ok, Term.const(:Nat)}

  defp vec_field_type(shape, %{position: 2}, frame) do
    with {:ok, a} <- Frame.ref(frame, :a),
         {:ok, n} <- newest_field_ref(frame) do
      {:ok, Term.const(:Vec, Indexed.statement_levels(shape)) |> Term.app(a) |> Term.app(n)}
    end
  end

  defp constructor_application(shape, alternative, frame, field_binders) do
    with {:ok, parameters} <- Indexed.refs_for_names(frame, Keyword.keys(shape.parameters)),
         {:ok, fields} <- field_refs(frame, field_binders) do
      arguments = parameters ++ fields

      {:ok,
       alternative.constructor
       |> Term.const(Indexed.statement_levels(shape))
       |> Indexed.apply_args(arguments)}
    end
  end

  defp alternative_application(
         %{family: :Vec} = shape,
         matcher,
         frame,
         alternative,
         field_binders
       ) do
    with {:ok, fields} <- field_refs(frame, field_binders),
         {:ok, ihs} <- recursive_hypotheses(shape, matcher, frame, field_binders),
         {:ok, alternative_ref} <- Frame.ref(frame, alternative.binder_name) do
      {:ok, Indexed.apply_args(alternative_ref, fields ++ ihs)}
    end
  end

  defp recursive_hypotheses(%{family: :Vec} = shape, matcher, frame, field_binders) do
    field_binders
    |> Enum.filter(& &1.field.recursive?)
    |> Enum.reduce_while({:ok, []}, fn recursive_field, {:ok, hypotheses} ->
      previous_fields = Enum.take(field_binders, recursive_field.field.position)

      with {:ok, major} <- Frame.ref(frame, recursive_field.name),
           {:ok, indices} <-
             instantiate_recursive_indices(previous_fields, frame, recursive_field),
           arguments = Enum.reverse([major | Enum.reverse(indices)]),
           {:ok, hypothesis} <- matcher_application(shape, matcher, frame, arguments) do
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

  defp field_refs(frame, field_binders) do
    field_binders
    |> Enum.map(& &1.name)
    |> then(&Indexed.refs_for_names(frame, &1))
  end

  defp matcher_application(shape, matcher, frame, [index, major]) do
    with {:ok, parameters} <- Indexed.refs_for_names(frame, Keyword.keys(shape.parameters)),
         {:ok, motive} <- Frame.ref(frame, shape.motive_name),
         {:ok, alternatives} <- alternative_refs(shape, frame) do
      arguments = parameters ++ [motive, index, major] ++ alternatives

      {:ok,
       matcher |> Term.const(Indexed.statement_levels(shape)) |> Indexed.apply_args(arguments)}
    end
  end

  defp alternative_refs(shape, frame) do
    Indexed.refs_for_names(frame, Enum.map(shape.alternatives, & &1.binder_name))
  end

  defp field_binder_pairs(field_binders) do
    Enum.map(field_binders, &{&1.name, &1.type})
  end

  defp instantiate_recursive_indices(field_binders, frame, recursive_field) do
    recursive_field.field.recursive_indices
    |> Enum.reduce_while({:ok, []}, fn index, {:ok, indices} ->
      case instantiate_field_term(index, field_binders, frame) do
        {:ok, term} -> {:cont, {:ok, [term | indices]}}
        {:error, _reason} = error -> {:halt, error}
      end
    end)
    |> case do
      {:ok, indices} -> {:ok, Enum.reverse(indices)}
      {:error, _reason} = error -> error
    end
  end

  defp instantiate_field_term(term, field_binders, frame) do
    field_count = length(field_binders)

    case term do
      %Term.BVar{index: index} when index < field_count ->
        field_binder = field_binder_by_reverse_index(field_binders, index)
        Frame.ref(frame, field_binder.name)

      %Term.BVar{index: index} ->
        {:error, {:unknown_indexed_matcher_statement_field_index, index}}

      %Term.App{fun: fun, arg: arg} ->
        with {:ok, fun} <- instantiate_field_term(fun, field_binders, frame),
             {:ok, arg} <- instantiate_field_term(arg, field_binders, frame) do
          {:ok, Term.app(fun, arg)}
        end

      other ->
        {:ok, other}
    end
  end

  defp field_binder_by_reverse_index(field_binders, target_index) do
    field_binders
    |> Enum.reverse()
    |> field_binder_at(target_index)
  end

  defp field_binder_at([field_binder | _rest], 0), do: field_binder
  defp field_binder_at([_field_binder | rest], index), do: field_binder_at(rest, index - 1)

  defp newest_field_ref(frame) do
    case Frame.binders(frame) do
      [] -> {:error, {:unknown_indexed_matcher_statement_binder, :field}}
      binders -> Frame.ref(frame, elem(List.last(binders), 0))
    end
  end

  defp case_binders(alternative), do: Indexed.collect_foralls(alternative.binder_type)
end
