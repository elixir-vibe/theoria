defmodule Theoria.Rewrite.Database do
  @moduledoc "Experimental/internal API for 0.2; subject to change before 0.3. A tiny untrusted rewrite-rule database."

  alias Theoria.Env
  alias Theoria.Equation.Eqns
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
    Eqns.database(env, opts)
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
