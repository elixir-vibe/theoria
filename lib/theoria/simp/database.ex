defmodule Theoria.Simp.Database do
  @moduledoc "Experimental/internal API for 0.2; subject to change before 0.3. Untrusted simplifier database with rule priorities."

  alias Theoria.Env
  alias Theoria.Equation.Eqns
  alias Theoria.Rewrite
  alias Theoria.Rewrite.Database, as: RewriteDatabase
  alias Theoria.Rewrite.Proof
  alias Theoria.Rewrite.Proof.Result, as: ProofResult
  alias Theoria.Simp.Rule
  alias Theoria.Term

  defstruct rules: []

  @type t :: %__MODULE__{rules: [Rule.t()]}

  @doc "Builds a simplifier database sorted by descending priority."
  @spec new([Rule.t()]) :: t()
  def new(rules \\ []) when is_list(rules) do
    %__MODULE__{rules: Enum.sort_by(rules, & &1.priority, :desc)}
  end

  @doc "Builds a simplifier database from generated environment equations."
  @spec from_env_equations(Env.t(), keyword()) :: t()
  def from_env_equations(%Env{} = env, opts \\ []) do
    env
    |> Eqns.database(opts)
    |> then(fn database -> Enum.map(database.rules, &Rule.new(&1, source: :equation)) end)
    |> new()
  end

  @doc "Builds a simplifier database from installed indexed matcher equations."
  @spec from_env_indexed_matcher_equations(Env.t(), keyword()) :: t()
  def from_env_indexed_matcher_equations(%Env{} = env, opts \\ []) do
    env
    |> RewriteDatabase.from_env_indexed_matcher_equations(opts)
    |> then(fn database ->
      Enum.map(database.rules, &Rule.new(&1, source: :matcher_equation))
    end)
    |> new()
  end

  @doc "Builds a simplifier database from generated definition and matcher equations."
  @spec from_env_all_equations(Env.t(), keyword()) :: t()
  def from_env_all_equations(%Env{} = env, opts \\ []) do
    env
    |> RewriteDatabase.from_env_all_equations(opts)
    |> then(fn database ->
      Enum.map(database.rules, &Rule.new(&1, source: equation_source(&1)))
    end)
    |> new()
  end

  defp equation_source(%{identity: %{kind: kind}})
       when kind in [:matcher_equation, :indexed_matcher_equation],
       do: :matcher_equation

  defp equation_source(_rule), do: :equation

  @doc "Applies the first matching simplifier rule."
  @spec once(t(), Term.t()) :: {:ok, Term.t(), Rule.t()} | :not_found
  def once(%__MODULE__{} = database, term) do
    case once_with_step(database, term) do
      {:ok, step, rule} -> {:ok, step.after, rule}
      :not_found -> :not_found
    end
  end

  @doc "Applies the first matching simplifier rule and returns rewrite-step metadata."
  @spec once_with_step(t(), Term.t()) :: {:ok, Theoria.Rewrite.Step.t(), Rule.t()} | :not_found
  def once_with_step(%__MODULE__{rules: rules}, term) do
    Enum.find_value(rules, :not_found, fn rule ->
      case Rewrite.once_with_step(term, rule.rewrite) do
        {:ok, step} -> {:ok, step, rule}
        :not_found -> false
      end
    end)
  end

  @doc "Applies the first matching simplifier rule with lazy proof realization support."
  @spec once_with_step(t(), Env.t(), Term.t(), keyword()) ::
          {:ok, Theoria.Rewrite.Step.t(), Rule.t()} | :not_found
  def once_with_step(%__MODULE__{rules: rules}, %Env{} = env, term, opts \\ []) do
    Enum.find_value(rules, :not_found, fn rule ->
      case Rewrite.once_with_step(term, rule.rewrite) do
        {:ok, step} ->
          {step, rule} = realize_selected_step(step, rule, env, opts)
          {:ok, step, rule}

        :not_found ->
          false
      end
    end)
  end

  defp realize_selected_step(step, rule, env, opts) do
    if Keyword.get(opts, :realize, false) == :lazy do
      rewrite = Rewrite.Rule.realize(env, step.rule, opts)

      {%{
         step
         | rule: rewrite,
           proof_result:
             rewrite
             |> Proof.instantiate_rule(step.substitution)
             |> then(&if(&1, do: ProofResult.checked(&1, Proof.Capabilities.explain(step.path))))
       }, %{rule | rewrite: rewrite}}
    else
      {step, rule}
    end
  end
end
