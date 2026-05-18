defmodule Theoria.Equation.MatcherEqns do
  @moduledoc "Experimental/internal API for 0.1; subject to change before 0.2. Lookup helpers for generated matcher equation metadata."

  alias Theoria.Env
  alias Theoria.Env.Matcher, as: EnvMatcher
  alias Theoria.Equation.Info
  alias Theoria.Equation.Lemma
  alias Theoria.Equation.MatcherEquation

  @doc "Returns generated matcher equation theorem names for a matcher."
  @spec get(Env.t(), atom()) :: {:ok, [atom()]} | {:error, term()}
  def get(%Env{} = env, matcher_name) when is_atom(matcher_name) do
    case generated(env, matcher_name) do
      {:ok, equations} -> {:ok, Enum.map(equations, & &1.name)}
      {:error, _reason} = error -> error
    end
  end

  @doc "Returns generated matcher equation metadata for a matcher declaration."
  @spec generated(Env.t(), atom()) :: {:ok, [MatcherEquation.t()]} | {:error, term()}
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
