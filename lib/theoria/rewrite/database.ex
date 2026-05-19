defmodule Theoria.Rewrite.Database do
  @moduledoc "Experimental/internal API for 0.2; subject to change before 0.3. A tiny untrusted rewrite-rule database."

  alias Theoria.Env
  alias Theoria.Equation.Eqns
  alias Theoria.Equation.Info
  alias Theoria.Equation.Lemma
  alias Theoria.Equation.Matcher.Eqns, as: MatcherEqns
  alias Theoria.Equation.Matcher.Equation, as: MatcherEquation
  alias Theoria.Rewrite
  alias Theoria.Rewrite.Proof
  alias Theoria.Rewrite.Proof.Result, as: ProofResult
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
    |> Enum.map(&matcher_rule(env, &1, opts))
    |> new()
  end

  @doc "Builds a rewrite database from installed indexed matcher equation metadata."
  @spec from_env_indexed_matcher_equations(Env.t(), keyword()) :: t()
  def from_env_indexed_matcher_equations(%Env{} = env, opts \\ []) do
    env
    |> Env.matchers()
    |> Enum.filter(&(&1.mode == :indexed_matcher and &1.equation_identities != []))
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
    with {:ok, info} <- indexed_matcher_info(matcher),
         {:ok, lemmas} <- MatcherEqns.indexed_lemmas(info, env) do
      Enum.map(lemmas, &Rule.from_realizing_lemma(env, &1, opts))
    else
      {:error, _reason} -> []
    end
  end

  defp matcher_rule(env, equation, opts) do
    lemma = MatcherEquation.to_lemma(equation)

    if Keyword.get(opts, :realize, false) do
      case MatcherEqns.realize(env, equation.identity) do
        {:ok, realized} ->
          Rule.from_lemma(lemma, Keyword.merge(opts, proof: realized.proof, realized: realized))

        {:error, _reason} ->
          Rule.from_lemma(lemma, opts)
      end
    else
      Rule.from_lemma(lemma, opts)
    end
  end

  defp indexed_matcher_info(%{schema: nil}), do: {:error, :missing_indexed_matcher_schema}

  defp indexed_matcher_info(matcher) do
    {:ok,
     Info.new(matcher.source, Term.const(matcher.source), Term.const(matcher.source),
       matcher: matcher.info,
       schema: matcher.schema,
       level_params: matcher.level_params
     )}
  end

  @doc "Applies the first rule that rewrites the term."
  @spec once(t(), Term.t()) :: {:ok, Term.t(), Rule.t()} | :not_found
  def once(%__MODULE__{} = database, term) do
    case once_with_step(database, term) do
      {:ok, step} -> {:ok, step.after, step.rule}
      :not_found -> :not_found
    end
  end

  @doc "Applies the first matching rule and returns rewrite-step metadata."
  @spec once_with_step(t(), Term.t()) :: {:ok, Theoria.Rewrite.Step.t()} | :not_found
  def once_with_step(%__MODULE__{rules: rules}, term) do
    Enum.find_value(Enum.reverse(rules), :not_found, fn rule ->
      case Rewrite.once_with_step(term, rule) do
        {:ok, step} -> {:ok, step}
        :not_found -> false
      end
    end)
  end

  @doc "Applies the first matching rule, realizing lazy rule proofs only after selection."
  @spec once_with_step(t(), Env.t(), Term.t(), keyword()) ::
          {:ok, Theoria.Rewrite.Step.t()} | :not_found
  def once_with_step(%__MODULE__{rules: rules}, %Env{} = env, term, opts \\ []) do
    Enum.find_value(Enum.reverse(rules), :not_found, fn rule ->
      case Rewrite.once_with_step(term, rule) do
        {:ok, step} -> {:ok, realize_selected_step(step, env, opts)}
        :not_found -> false
      end
    end)
  end

  defp realize_selected_step(step, env, opts) do
    if Keyword.get(opts, :realize, false) == :lazy do
      rule = Rule.realize(env, step.rule, opts)

      %{
        step
        | rule: rule,
          proof_result:
            rule
            |> Proof.instantiate_rule(step.substitution)
            |> then(&if(&1, do: ProofResult.checked(&1, Proof.Capabilities.explain(step.path))))
      }
    else
      step
    end
  end
end
