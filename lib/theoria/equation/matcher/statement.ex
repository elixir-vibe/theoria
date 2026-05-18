defmodule Theoria.Equation.Matcher.Statement do
  @moduledoc "Experimental/internal API for 0.2; subject to change before 0.3. Statement planning for matcher equations."

  alias Theoria.Equation.Matcher.Equation, as: MatcherEquation
  alias Theoria.Term

  defmodule Frame do
    @moduledoc false

    alias Theoria.Term

    @enforce_keys [:binders]
    defstruct [:binders]

    def new(binders), do: %__MODULE__{binders: binders}

    def push(%__MODULE__{binders: binders}, name, type),
      do: %__MODULE__{binders: binders ++ [{name, type}]}

    def push_many(frame, binders) do
      Enum.reduce(binders, frame, fn {name, type}, acc -> push(acc, name, type) end)
    end

    def binders(%__MODULE__{binders: binders}), do: binders

    def ref(%__MODULE__{binders: binders}, name) do
      index =
        binders
        |> Enum.reverse()
        |> Enum.find_index(&(elem(&1, 0) == name))

      if is_nil(index),
        do: raise(ArgumentError, "unknown matcher equation binder #{inspect(name)}")

      Term.bvar(index)
    end

    def forall(%__MODULE__{} = frame, body), do: forall_telescope(binders(frame), body)

    defp forall_telescope(binders, result) do
      Enum.reduce(Enum.reverse(binders), result, fn {name, type}, body ->
        Term.forall(name, type, body)
      end)
    end
  end

  @doc "Builds an indexed matcher equation theorem statement."
  @spec indexed(term(), MatcherEquation.t()) :: Term.t()
  def indexed(shape, %MatcherEquation{} = equation) do
    case find_alternative(shape, equation.constructor) do
      nil -> equation.equality_type
      alternative -> indexed_for_alternative(shape, equation, alternative)
    end
  end

  @doc "Builds indexed matcher equation statements for every equation."
  @spec indexed_all(term(), [MatcherEquation.t()]) :: [MatcherEquation.t()]
  def indexed_all(shape, equations) do
    Enum.map(equations, &%{&1 | statement_type: indexed(shape, &1)})
  end

  defp indexed_for_alternative(
         shape,
         %MatcherEquation{constructor: :vec_nil} = equation,
         alternative
       ) do
    frame = base_frame(shape)
    index = hd(alternative.index_patterns)
    major = constructor_application(shape, alternative, frame)
    motive = Frame.ref(frame, shape.motive_name)
    result_type = motive |> Term.app(index) |> Term.app(major)
    lhs = matcher_application(shape, equation.matcher, frame, [index, major])
    rhs = Frame.ref(frame, alternative.binder_name)

    Frame.forall(frame, Term.eq(result_type, lhs, rhs))
  end

  defp indexed_for_alternative(
         shape,
         %MatcherEquation{constructor: :vec_cons} = equation,
         alternative
       ) do
    base = base_frame(shape)
    field_binders = constructor_field_binders(shape, alternative, base)
    frame = Frame.push_many(base, field_binders)
    index = hd(alternative.index_patterns)
    major = constructor_application(shape, alternative, frame)
    motive = Frame.ref(frame, shape.motive_name)
    result_type = motive |> Term.app(index) |> Term.app(major)
    lhs = matcher_application(shape, equation.matcher, frame, [index, major])
    rhs = alternative_application(shape, equation.matcher, frame, alternative)

    Frame.forall(frame, Term.eq(result_type, lhs, rhs))
  end

  defp indexed_for_alternative(_shape, %MatcherEquation{} = equation, _alternative),
    do: equation.equality_type

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

    {binders, _frame} =
      alternative.fields
      |> Enum.zip(names)
      |> Enum.reduce({[], frame}, fn {field, name}, {binders, current_frame} ->
        type = vec_field_type(field, current_frame)
        {[{name, type} | binders], Frame.push(current_frame, name, type)}
      end)

    Enum.reverse(binders)
  end

  defp constructor_field_binders(_shape, alternative, _frame),
    do: Enum.take(case_binders(alternative), length(alternative.fields))

  defp vec_field_type(%{position: 0}, frame), do: Frame.ref(frame, :a)
  defp vec_field_type(%{position: 1}, _frame), do: Term.const(:Nat)

  defp vec_field_type(%{position: 2}, frame) do
    Term.const(:Vec, [1])
    |> Term.app(Frame.ref(frame, :a))
    |> Term.app(Frame.ref(frame, :n))
  end

  defp constructor_application(shape, alternative, frame) do
    shape.parameters
    |> Keyword.keys()
    |> Enum.map(&Frame.ref(frame, &1))
    |> Kernel.++(field_refs(alternative, frame))
    |> Enum.reduce(Term.const(alternative.constructor, [1]), fn argument, term ->
      Term.app(term, argument)
    end)
  end

  defp alternative_application(%{family: :Vec} = shape, matcher, frame, alternative) do
    ihs = recursive_hypotheses(shape, matcher, frame, alternative)

    alternative
    |> field_refs(frame)
    |> Kernel.++(ihs)
    |> Enum.reduce(Frame.ref(frame, alternative.binder_name), fn argument, term ->
      Term.app(term, argument)
    end)
  end

  defp recursive_hypotheses(%{family: :Vec} = shape, matcher, frame, alternative) do
    alternative.fields
    |> Enum.filter(& &1.recursive?)
    |> Enum.map(fn _field ->
      matcher_application(shape, matcher, frame, [Frame.ref(frame, :n), Frame.ref(frame, :arg2)])
    end)
  end

  defp field_refs(alternative, frame) do
    alternative
    |> case_binders()
    |> Enum.take(length(alternative.fields))
    |> Enum.map(fn {name, _type} -> Frame.ref(frame, name) end)
  end

  defp matcher_application(shape, matcher, frame, [index, major]) do
    arguments =
      shape.parameters
      |> Keyword.keys()
      |> Enum.map(&Frame.ref(frame, &1))
      |> Kernel.++([Frame.ref(frame, shape.motive_name), index, major])
      |> Kernel.++(alternative_refs(shape, frame))

    Enum.reduce(arguments, Term.const(matcher, [1]), fn argument, term ->
      Term.app(term, argument)
    end)
  end

  defp alternative_refs(shape, frame) do
    Enum.map(shape.alternatives, &Frame.ref(frame, &1.binder_name))
  end

  defp case_binders(alternative), do: collect_foralls(alternative.binder_type)

  defp collect_foralls(%Term.Forall{name: name, domain: domain, body: body}) do
    [{name, domain} | collect_foralls(body)]
  end

  defp collect_foralls(_body), do: []

  defp find_alternative(shape, constructor),
    do: Enum.find(shape.alternatives, &(&1.constructor == constructor))
end
