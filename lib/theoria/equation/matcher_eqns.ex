defmodule Theoria.Equation.MatcherEqns do
  @moduledoc "Lookup helpers for generated matcher equation metadata."

  alias Theoria.Env
  alias Theoria.Equation.Info
  alias Theoria.Equation.Lemma
  alias Theoria.Equation.MatcherEquation

  @doc "Returns generated matcher equation theorem names for a matcher."
  @spec get(Env.t(), atom()) :: {:ok, [atom()]} | {:error, term()}
  def get(%Env{} = env, matcher_name) when is_atom(matcher_name) do
    case info_for_matcher(env, matcher_name) do
      {:ok, info} -> {:ok, info |> generated() |> Enum.map(& &1.name)}
      {:error, _reason} = error -> error
    end
  end

  @doc "Returns generated matcher equation metadata for a stored equation definition."
  @spec generated(Info.t()) :: [MatcherEquation.t()]
  def generated(%Info{matcher: nil}), do: []

  def generated(%Info{} = info) do
    alternatives = Enum.map(info.matcher.alternatives, & &1.constructor)
    lemmas = Lemma.generated_for(info)

    alternatives
    |> Enum.zip(lemmas)
    |> Enum.map(fn {constructor, lemma} ->
      MatcherEquation.from_lemma(info.matcher.name, constructor, lemma)
    end)
  end

  @doc "Returns all generated matcher equation metadata in declaration order."
  @spec all(Env.t()) :: [MatcherEquation.t()]
  def all(%Env{} = env) do
    env
    |> Info.all()
    |> Enum.flat_map(&generated/1)
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

  defp info_for_matcher(env, matcher_name) do
    env
    |> Info.all()
    |> Enum.find_value({:error, {:unknown_matcher, matcher_name}}, fn info ->
      if info.matcher && info.matcher.name == matcher_name do
        {:ok, info}
      else
        false
      end
    end)
  end
end
