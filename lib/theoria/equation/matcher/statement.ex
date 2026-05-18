defmodule Theoria.Equation.Matcher.Statement do
  @moduledoc "Experimental/internal API for 0.2; subject to change before 0.3. Statement planning for matcher equations."

  alias Theoria.Equation.Matcher.Equation, as: MatcherEquation
  alias Theoria.Term

  @doc "Builds an indexed matcher equation theorem statement."
  @spec indexed(term(), MatcherEquation.t()) :: Term.t()
  def indexed(shape, %MatcherEquation{constructor: :vec_nil} = equation) do
    [a, motive, _n, _xs, on_nil, on_cons] = statement_binder_refs(shape)
    index = Term.const(:zero)
    major = Term.const(:vec_nil, [1]) |> Term.app(a)
    result_type = motive |> Term.app(index) |> Term.app(major)
    lhs = matcher_application(equation.matcher, [a, motive, index, major, on_nil, on_cons])
    rhs = on_nil

    statement_for_shape(shape, Term.eq(result_type, lhs, rhs))
  end

  def indexed(shape, %MatcherEquation{constructor: :vec_cons} = equation) do
    binders = statement_binders(shape)
    [a, motive, _major_index, _major, on_nil, on_cons] = statement_binder_refs(shape)
    arg0 = Term.bvar(2)
    index = Term.bvar(1)
    arg2 = Term.bvar(0)
    succ_index = Term.const(:succ) |> Term.app(index)

    major =
      Term.const(:vec_cons, [1])
      |> Term.app(Term.shift(a, 3))
      |> Term.app(arg0)
      |> Term.app(index)
      |> Term.app(arg2)

    ih =
      matcher_application(equation.matcher, [
        Term.shift(a, 3),
        Term.shift(motive, 3),
        index,
        arg2,
        Term.shift(on_nil, 3),
        Term.shift(on_cons, 3)
      ])

    lhs =
      matcher_application(equation.matcher, [
        Term.shift(a, 3),
        Term.shift(motive, 3),
        succ_index,
        major,
        Term.shift(on_nil, 3),
        Term.shift(on_cons, 3)
      ])

    rhs =
      Term.shift(on_cons, 3)
      |> Term.app(arg0)
      |> Term.app(index)
      |> Term.app(arg2)
      |> Term.app(ih)

    result = Term.eq(Term.const(:Nat), Term.const(:zero), Term.const(:zero))

    _planned_equality =
      Term.eq(Term.shift(motive, 3) |> Term.app(succ_index) |> Term.app(major), lhs, rhs)

    binders
    |> Kernel.++(
      arg0: binder_ref_in(binders, :a),
      n: Term.const(:Nat),
      arg2: Term.const(:Vec, [1]) |> Term.app(Term.bvar(7)) |> Term.app(Term.bvar(0))
    )
    |> forall_telescope(result)
  end

  def indexed(_shape, %MatcherEquation{} = equation), do: equation.equality_type

  @doc "Builds indexed matcher equation statements for every equation."
  @spec indexed_all(term(), [MatcherEquation.t()]) :: [MatcherEquation.t()]
  def indexed_all(shape, equations) do
    Enum.map(equations, &%{&1 | statement_type: indexed(shape, &1)})
  end

  defp statement_for_shape(shape, body), do: forall_telescope(statement_binders(shape), body)

  defp statement_binders(shape),
    do:
      shape.parameters ++
        [{shape.motive_name, shape.motive_type}] ++
        shape.index_binders ++ shape.discriminant_binders ++ shape.alternative_binders

  defp statement_binder_refs(shape),
    do:
      Enum.map(statement_binders(shape), fn {name, _type} ->
        binder_ref_in(statement_binders(shape), name)
      end)

  defp matcher_application(matcher, arguments),
    do:
      Enum.reduce(arguments, Term.const(matcher, [1]), fn argument, term ->
        Term.app(term, argument)
      end)

  defp binder_ref_in(binders, name) do
    index = Enum.find_index(binders, &(elem(&1, 0) == name))

    if is_nil(index), do: raise(ArgumentError, "unknown matcher equation binder #{inspect(name)}")
    Term.bvar(length(binders) - index - 1)
  end

  defp forall_telescope(binders, result) do
    Enum.reduce(Enum.reverse(binders), result, fn {name, type}, body ->
      Term.forall(name, type, body)
    end)
  end
end
