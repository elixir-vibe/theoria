defmodule Theoria.Simp do
  @moduledoc "Tiny untrusted simplification groundwork backed by generated equation rules."

  alias Theoria.Env
  alias Theoria.Rewrite.Database
  alias Theoria.Term

  @type step :: {atom(), Term.t()}
  @type result :: %{term: Term.t(), steps: [step()], stopped: :normal | :fuel}

  @doc "Applies one generated equation rewrite, if possible."
  @spec once(Env.t(), Term.t(), keyword()) :: {:ok, Term.t(), atom()} | :not_found
  def once(%Env{} = env, term, opts \\ []) do
    env
    |> Database.from_env_equations(opts)
    |> Database.once(term)
    |> case do
      {:ok, term, rule} -> {:ok, term, rule.name}
      :not_found -> :not_found
    end
  end

  @doc "Repeatedly applies generated equation rewrites until normal form or fuel exhaustion."
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
        normalize_with_database(database, next, remaining - 1, [{rule.name, next} | steps])

      :not_found ->
        %{term: term, steps: Enum.reverse(steps), stopped: :normal}
    end
  end
end
