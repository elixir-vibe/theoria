defmodule Theoria.Equation.Matcher.Eqns do
  @moduledoc "Experimental/internal API for 0.2; subject to change before 0.3. Lookup helpers for generated matcher equation metadata."

  alias Theoria.Env
  alias Theoria.Env.Matcher, as: EnvMatcher
  alias Theoria.Equation.Info
  alias Theoria.Equation.Lemma
  alias Theoria.Equation.Matcher.Descriptor, as: MatcherDescriptor
  alias Theoria.Equation.Matcher.Equation, as: MatcherEquation
  alias Theoria.Equation.Matcher.Indexed.Package, as: IndexedPackage
  alias Theoria.Equation.Matcher.Indexed.Realization, as: IndexedRealization
  alias Theoria.Equation.Matcher.Statement, as: MatcherStatement
  alias Theoria.Equation.Matcher.Type, as: MatcherType
  alias Theoria.Equation.Name
  alias Theoria.Term

  @doc "Returns generated matcher equation theorem names for a matcher."
  @spec get(Env.t(), atom()) :: {:ok, [Name.t()]} | {:error, term()}
  def get(%Env{} = env, matcher_name) when is_atom(matcher_name) do
    case generated(env, matcher_name) do
      {:ok, equations} -> {:ok, Enum.map(equations, & &1.id)}
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
  @spec indexed_statement(Info.t(), Env.t(), Name.t() | keyword()) ::
          {:ok, Term.t()} | {:error, term()}
  def indexed_statement(%Info{} = info, %Env{} = env, selector) do
    with {:ok, equations} <- indexed_generated(info, env),
         {:ok, equation_name} <- Name.cast(selector, info.matcher.name, :indexed_matcher_equation),
         %MatcherEquation{} = equation <-
           Enum.find(equations, &(&1.id == equation_name)) ||
             {:error, {:unknown_indexed_matcher_equation, equation_name}},
         {:ok, descriptor} <- MatcherDescriptor.from_env(env, info.schema, info.matcher),
         {:ok, shape} <- MatcherType.shape_from_descriptor(descriptor) do
      MatcherStatement.indexed(shape, equation)
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
      MatcherStatement.indexed_all(shape, equations)
    end
  end

  @doc "Returns metadata-only lemmas for planned indexed matcher equation statements."
  @spec indexed_lemmas(Info.t(), Env.t()) :: {:ok, [Lemma.t()]} | {:error, term()}
  def indexed_lemmas(%Info{} = info, %Env{} = env) do
    with {:ok, statements} <- indexed_statements(info, env) do
      indexed_lemmas_for(statements)
    end
  end

  @doc "Realizes a planned indexed matcher equation theorem without installing it."
  @spec indexed_realize(Info.t(), Env.t(), Name.t() | keyword()) ::
          {:ok, Theoria.Theorem.t()} | {:error, term()}
  def indexed_realize(%Info{} = info, %Env{} = env, selector) do
    with {:ok, theorem_name} <- Name.cast(selector, info.matcher.name, :indexed_matcher_equation),
         {:ok, package} <- IndexedPackage.build(info, env) do
      IndexedRealization.realize(package, theorem_name)
    end
  end

  @doc "Realizes all planned indexed matcher equation theorems without installing them."
  @spec indexed_realize_all(Info.t(), Env.t()) :: {:ok, [Theoria.Theorem.t()]} | {:error, term()}
  def indexed_realize_all(%Info{} = info, %Env{} = env) do
    with {:ok, package} <- IndexedPackage.build(info, env) do
      IndexedRealization.realize_all(package)
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
  @spec source(Env.t(), Name.t() | atom()) :: {:ok, atom()} | :error
  def source(%Env{} = env, theorem_name),
    do: source_declaration(env, declaration_name(theorem_name))

  defp source_declaration(env, theorem_name) do
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
  @spec realize(Env.t(), Name.t() | atom()) :: {:ok, Theoria.Theorem.t()} | {:error, term()}
  def realize(%Env{} = env, %Name{} = theorem_name) do
    realize_declaration(env, theorem_name)
  end

  def realize(%Env{} = env, theorem_name) when is_atom(theorem_name) do
    realize_declaration(env, theorem_name)
  end

  defp realize_declaration(env, theorem_name) do
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

  defp declaration_name(%Name{} = name), do: name
  defp declaration_name(name) when is_atom(name), do: name

  defp indexed_lemmas_for(statements) do
    Enum.reduce_while(statements, {:ok, []}, fn equation, {:ok, lemmas} ->
      case MatcherStatement.indexed_to_lemma(equation) do
        {:ok, lemma} -> {:cont, {:ok, [lemma | lemmas]}}
        {:error, _reason} = error -> {:halt, error}
      end
    end)
    |> case do
      {:ok, lemmas} -> {:ok, Enum.reverse(lemmas)}
      {:error, _reason} = error -> error
    end
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
