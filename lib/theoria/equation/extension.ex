defmodule Theoria.Equation.Extension do
  @moduledoc "Typed registry helpers for generated equation and matcher metadata."

  alias Theoria.Env
  alias Theoria.Env.Matcher, as: EnvMatcher
  alias Theoria.Equation.Info
  alias Theoria.Equation.Lemma
  alias Theoria.Equation.MatcherEqns

  @doc "Returns equation definitions known to the registry."
  @spec definitions(Env.t()) :: [Info.t()]
  def definitions(%Env{} = env), do: Info.all(env)

  @doc "Returns matcher declarations known to the registry."
  @spec matchers(Env.t()) :: [EnvMatcher.t()]
  def matchers(%Env{} = env), do: Env.matchers(env)

  @doc "Returns matcher declarations generated for a source definition."
  @spec matchers_for(Env.t(), atom()) :: [EnvMatcher.t()]
  def matchers_for(%Env{} = env, source) when is_atom(source) do
    env
    |> matchers()
    |> Enum.filter(&(&1.source == source))
  end

  @doc "Returns the source definition or matcher for a generated theorem name."
  @spec source_for(Env.t(), atom()) :: {:ok, atom()} | :error
  def source_for(%Env{} = env, theorem_name) when is_atom(theorem_name) do
    ordinary_source_for(env, theorem_name) || matcher_source_for(env, theorem_name) || :error
  end

  @doc "Returns generated ordinary equation names for a source definition."
  @spec equation_names(Info.t()) :: [atom()]
  def equation_names(%Info{} = info), do: Enum.map(Lemma.generated_for(info), & &1.name)

  @doc "Returns generated matcher equation names for a matcher declaration."
  @spec matcher_equation_names(Env.t(), EnvMatcher.t()) :: [atom()]
  def matcher_equation_names(%Env{} = env, %EnvMatcher{} = matcher) do
    case MatcherEqns.generated(env, matcher.name) do
      {:ok, equations} -> Enum.map(equations, & &1.name)
      {:error, _reason} -> []
    end
  end

  defp ordinary_source_for(env, theorem_name) do
    env
    |> definitions()
    |> Enum.find_value(fn info ->
      names = [Lemma.unfold_for(info).name | equation_names(info)]

      if theorem_name in names do
        {:ok, info.name}
      else
        false
      end
    end)
  end

  defp matcher_source_for(env, theorem_name) do
    env
    |> matchers()
    |> Enum.find_value(fn matcher ->
      if theorem_name in matcher_equation_names(env, matcher) do
        {:ok, matcher.name}
      else
        false
      end
    end)
  end
end
