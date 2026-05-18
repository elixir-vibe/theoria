defmodule Theoria.Rewrite.Database do
  @moduledoc "Experimental/internal API for 0.2; subject to change before 0.3. A tiny untrusted rewrite-rule database."

  alias Theoria.Env
  alias Theoria.Equation.Eqns
  alias Theoria.Equation.Lemma
  alias Theoria.Equation.Matcher.Eqns, as: MatcherEqns
  alias Theoria.Equation.Matcher.Equation, as: MatcherEquation
  alias Theoria.Equation.Matcher.Indexed.Vec, as: IndexedVec
  alias Theoria.Rewrite
  alias Theoria.Rewrite.Rule
  alias Theoria.Term

  defstruct rules: []

  @type t :: %__MODULE__{rules: [Rule.t()]}

  @doc "Builds an empty rewrite database."
  @spec new([Rule.t()]) :: t()
  def new(rules \\ []) when is_list(rules), do: %__MODULE__{rules: rules}

  @doc "Adds a rule to the database."
  @spec add(t(), Rule.t()) :: t()
  def add(%__MODULE__{rules: rules} = database, %Rule{} = rule),
    do: %{database | rules: [rule | rules]}

  @doc "Builds a rewrite database from equation-lemma metadata."
  @spec from_lemmas([Lemma.t()], Term.t(), keyword()) :: t()
  def from_lemmas(lemmas, equality_type, opts \\ []) when is_list(lemmas) do
    lemmas
    |> Enum.map(&Rule.from_lemma(&1, equality_type, opts))
    |> new()
  end

  @doc "Builds a rewrite database from generated equation metadata stored in an environment."
  @spec from_env_equations(Env.t(), keyword()) :: t()
  def from_env_equations(%Env{} = env, opts \\ []) do
    Eqns.database(env, opts)
  end

  @doc "Builds a rewrite database from generated matcher equations stored in an environment."
  @spec from_env_matcher_equations(Env.t(), keyword()) :: t()
  def from_env_matcher_equations(%Env{} = env, opts \\ []) do
    env
    |> MatcherEqns.all()
    |> Enum.reject(& &1.indexed?)
    |> Enum.map(&(&1 |> MatcherEquation.to_lemma() |> Rule.from_lemma(opts)))
    |> new()
  end

  @doc "Builds a rewrite database from installed indexed matcher equation metadata."
  @spec from_env_indexed_matcher_equations(Env.t(), keyword()) :: t()
  def from_env_indexed_matcher_equations(%Env{} = env, opts \\ []) do
    env
    |> Env.matchers()
    |> Enum.filter(&(&1.mode == :indexed_matcher and &1.equation_names != []))
    |> Enum.flat_map(&indexed_matcher_rules(env, &1, opts))
    |> new()
  end

  @doc "Builds a rewrite database from generated definition and matcher equations in an environment."
  @spec from_env_all_equations(Env.t(), keyword()) :: t()
  def from_env_all_equations(%Env{} = env, opts \\ []) do
    generated = from_env_equations(env, opts).rules
    matchers = from_env_matcher_equations(env, opts).rules
    indexed = indexed_rules(env, opts)
    new(generated ++ matchers ++ indexed)
  end

  defp indexed_rules(env, opts) do
    if Keyword.get(opts, :include_indexed_matchers, false) do
      from_env_indexed_matcher_equations(env, opts).rules
    else
      []
    end
  end

  defp indexed_matcher_rules(env, matcher, opts) do
    info = IndexedVec.info(matcher.name, matcher.source)

    case MatcherEqns.indexed_lemmas(info, env) do
      {:ok, lemmas} -> Enum.map(lemmas, &Rule.from_lemma(&1, opts))
      {:error, _reason} -> []
    end
  end

  @doc "Applies the first rule that rewrites the term."
  @spec once(t(), Term.t()) :: {:ok, Term.t(), Rule.t()} | :not_found
  def once(%__MODULE__{rules: rules}, term) do
    Enum.find_value(Enum.reverse(rules), :not_found, fn rule ->
      case Rewrite.once_rule(term, rule) do
        {:ok, term} -> {:ok, term, rule}
        :not_found -> false
      end
    end)
  end
end
