defmodule Theoria.Equation.Matcher.Eqns do
  @moduledoc "Experimental/internal API for 0.2; subject to change before 0.3. Lookup helpers for generated matcher equation metadata."

  alias Theoria.Env
  alias Theoria.Env.Matcher, as: EnvMatcher
  alias Theoria.Equation.Info
  alias Theoria.Equation.Lemma
  alias Theoria.Equation.Matcher.Descriptor, as: MatcherDescriptor
  alias Theoria.Equation.Matcher.Equation, as: MatcherEquation
  alias Theoria.Equation.Matcher.Type, as: MatcherType
  alias Theoria.Term

  @doc "Returns generated matcher equation theorem names for a matcher."
  @spec get(Env.t(), atom()) :: {:ok, [atom()]} | {:error, term()}
  def get(%Env{} = env, matcher_name) when is_atom(matcher_name) do
    case generated(env, matcher_name) do
      {:ok, equations} -> {:ok, Enum.map(equations, & &1.name)}
      {:error, _reason} = error -> error
    end
  end

  @doc "Returns generated matcher equation metadata for a matcher declaration."
  @spec generated(Env.t(), atom()) ::
          {:ok, [MatcherEquation.t()]} | {:error, term()}
  def generated(%Env{} = env, matcher_name) when is_atom(matcher_name) do
    with {:ok, matcher} <- fetch_matcher(env, matcher_name),
         {:ok, info} <- Info.fetch(env, matcher.source) do
      {:ok, generated_for_matcher(info, matcher)}
    end
  end

  @doc "Returns generated matcher equation metadata for a stored equation definition."
  @spec generated(Info.t()) :: [MatcherEquation.t()]
  def generated(%Info{matcher: nil}), do: []

  def generated(%Info{} = info) do
    generated_for_matcher(info, %EnvMatcher{
      name: info.matcher.name,
      source: info.name,
      type: info.type,
      value: info.value,
      info: info.matcher
    })
  end

  @doc "Returns planned indexed matcher equation metadata for an indexed matcher info package."
  @spec indexed_generated(Info.t(), Env.t()) :: {:ok, [MatcherEquation.t()]} | {:error, term()}
  def indexed_generated(%Info{matcher: nil}, _env), do: {:ok, []}

  def indexed_generated(%Info{} = info, %Env{} = env) do
    with {:ok, descriptor} <- MatcherDescriptor.from_env(env, info.schema, info.matcher),
         true <-
           descriptor.indexed? || {:error, {:not_indexed_matcher_equations, info.matcher.name}} do
      {:ok,
       Enum.map(descriptor.alternatives, fn alternative ->
         MatcherEquation.indexed(info.matcher.name, alternative.name, alternative.index_patterns)
       end)}
    else
      {:error, _reason} = error -> error
    end
  end

  @doc "Returns a planned indexed matcher equation theorem statement."
  @spec indexed_statement(Info.t(), Env.t(), atom()) :: {:ok, Term.t()} | {:error, term()}
  def indexed_statement(%Info{} = info, %Env{} = env, equation_name)
      when is_atom(equation_name) do
    with {:ok, equations} <- indexed_generated(info, env),
         %MatcherEquation{} = equation <-
           Enum.find(equations, &(&1.name == equation_name)) ||
             {:error, {:unknown_indexed_matcher_equation, equation_name}},
         {:ok, descriptor} <- MatcherDescriptor.from_env(env, info.schema, info.matcher),
         {:ok, shape} <- MatcherType.shape_from_descriptor(descriptor) do
      {:ok, indexed_statement_for(shape, equation)}
    else
      {:error, _reason} = error -> error
    end
  end

  @doc "Returns all planned indexed matcher equation theorem statements."
  @spec indexed_statements(Info.t(), Env.t()) :: {:ok, [MatcherEquation.t()]} | {:error, term()}
  def indexed_statements(%Info{} = info, %Env{} = env) do
    with {:ok, equations} <- indexed_generated(info, env),
         {:ok, descriptor} <- MatcherDescriptor.from_env(env, info.schema, info.matcher),
         {:ok, shape} <- MatcherType.shape_from_descriptor(descriptor) do
      {:ok, Enum.map(equations, &%{&1 | statement_type: indexed_statement_for(shape, &1)})}
    end
  end

  @doc "Returns all generated matcher equation metadata in declaration order."
  @spec all(Env.t()) :: [MatcherEquation.t()]
  def all(%Env{} = env) do
    env
    |> Env.matchers()
    |> Enum.flat_map(fn matcher ->
      case generated(env, matcher.name) do
        {:ok, equations} -> equations
        {:error, _reason} -> []
      end
    end)
  end

  @doc "Finds the matcher that generated a matcher equation theorem."
  @spec source(Env.t(), atom()) :: {:ok, atom()} | :error
  def source(%Env{} = env, theorem_name) when is_atom(theorem_name) do
    env
    |> all()
    |> Enum.find_value(:error, fn equation ->
      if equation.name == theorem_name do
        {:ok, equation.matcher}
      else
        false
      end
    end)
  end

  @doc "Converts matcher equations to theorem-like equation lemmas."
  @spec lemmas(Env.t()) :: [Lemma.t()]
  def lemmas(%Env{} = env), do: Enum.map(all(env), &MatcherEquation.to_lemma/1)

  @doc "Realizes a generated matcher equation theorem without installing it."
  @spec realize(Env.t(), atom()) :: {:ok, Theoria.Theorem.t()} | {:error, term()}
  def realize(%Env{} = env, theorem_name) when is_atom(theorem_name) do
    env
    |> all()
    |> Enum.find_value({:error, {:unknown_matcher_equation, theorem_name}}, fn equation ->
      if equation.name == theorem_name do
        Lemma.to_theorem(env, MatcherEquation.to_lemma(equation))
      else
        false
      end
    end)
  end

  defp indexed_statement_for(shape, %MatcherEquation{constructor: :vec_nil} = equation) do
    [a, motive, _n, _xs, on_nil, on_cons] = statement_binder_refs(shape)
    index = Term.const(:zero)
    major = Term.const(:vec_nil, [1]) |> Term.app(a)
    result_type = motive |> Term.app(index) |> Term.app(major)
    lhs = matcher_application(equation.matcher, [a, motive, index, major, on_nil, on_cons])
    rhs = on_nil

    statement_for_shape(shape, Term.eq(result_type, lhs, rhs))
  end

  defp indexed_statement_for(shape, %MatcherEquation{constructor: :vec_cons} = equation) do
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

    _lhs =
      matcher_application(equation.matcher, [
        Term.shift(a, 3),
        Term.shift(motive, 3),
        succ_index,
        major,
        Term.shift(on_nil, 3),
        Term.shift(on_cons, 3)
      ])

    _rhs =
      Term.shift(on_cons, 3)
      |> Term.app(arg0)
      |> Term.app(index)
      |> Term.app(arg2)
      |> Term.app(ih)

    binders
    |> Kernel.++(
      arg0: binder_ref_in(binders, :a),
      n: Term.const(:Nat),
      arg2: Term.const(:Vec, [1]) |> Term.app(Term.bvar(7)) |> Term.app(Term.bvar(0))
    )
    |> forall_telescope(Term.eq(Term.const(:Nat), Term.const(:zero), Term.const(:zero)))
  end

  defp indexed_statement_for(_shape, %MatcherEquation{} = equation), do: equation.equality_type

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

  defp generated_for_matcher(%Info{} = info, %EnvMatcher{} = matcher) do
    constructors = Enum.map(matcher.info.alternatives, & &1.constructor)
    lemmas = Lemma.generated_for(info)

    constructors
    |> Enum.zip(lemmas)
    |> Enum.map(fn {constructor, lemma} ->
      MatcherEquation.from_lemma(matcher.name, constructor, lemma)
    end)
  end

  defp fetch_matcher(env, matcher_name) do
    case Env.fetch_matcher(env, matcher_name) do
      {:ok, matcher} -> {:ok, matcher}
      :error -> {:error, {:unknown_matcher, matcher_name}}
    end
  end
end
