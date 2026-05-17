defmodule Theoria.Simp do
  @moduledoc "Tiny untrusted simplification groundwork backed by generated equation rules."

  alias Theoria.Env
  alias Theoria.Simp.Database
  alias Theoria.Simp.Step
  alias Theoria.Term

  @type result :: %{term: Term.t(), steps: [Step.t()], stopped: :normal | :fuel}

  @doc "Applies one generated equation simplification, if possible."
  @spec once(Env.t(), Term.t(), keyword()) :: {:ok, Term.t(), Step.t()} | :not_found
  def once(%Env{} = env, term, opts \\ []) do
    env
    |> Database.from_env_equations(opts)
    |> Database.once(term)
    |> case do
      {:ok, next, rule} -> {:ok, next, step(rule, term, next)}
      :not_found -> :not_found
    end
  end

  @doc "Repeatedly applies generated equation simplifications until normal form or fuel exhaustion."
  @spec normalize(Env.t(), Term.t(), keyword()) :: result()
  def normalize(%Env{} = env, term, opts \\ []) do
    max_steps = Keyword.get(opts, :max_steps, 100)
    database = Database.from_env_equations(env, opts)
    normalize_with_database(database, term, max_steps, [])
  end

  defp normalize_with_database(_database, term, 0, steps) do
    %{term: term, steps: Enum.reverse(steps), stopped: :fuel}
  end

  defp normalize_with_database(database, term, remaining, steps) do
    case Database.once(database, term) do
      {:ok, next, rule} ->
        normalize_with_database(database, next, remaining - 1, [step(rule, term, next) | steps])

      :not_found ->
        %{term: term, steps: Enum.reverse(steps), stopped: :normal}
    end
  end

  defp step(rule, before, after_term) do
    %Step{rule: rule.rewrite.name, before: before, after: after_term, source: rule.source}
  end
end
