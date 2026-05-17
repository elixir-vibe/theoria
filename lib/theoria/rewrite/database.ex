defmodule Theoria.Rewrite.Database do
  @moduledoc "A tiny untrusted rewrite-rule database."

  alias Theoria.Env
  alias Theoria.Equation.Info
  alias Theoria.Equation.Lemma
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
    env
    |> Info.all()
    |> Enum.flat_map(&rules_for_equation(&1, opts))
    |> new()
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

  defp rules_for_equation(info, opts) do
    equality_type = Lemma.equality_type_for!(info)

    info
    |> Lemma.generated_for(opts)
    |> Enum.map(&Rule.from_lemma(&1, equality_type, opts))
  rescue
    FunctionClauseError -> []
  end
end
