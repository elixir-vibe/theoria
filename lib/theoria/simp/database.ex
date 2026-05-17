defmodule Theoria.Simp.Database do
  @moduledoc "Untrusted simplifier database with rule priorities."

  alias Theoria.Env
  alias Theoria.Equation.Eqns
  alias Theoria.Rewrite
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

  @doc "Applies the first matching simplifier rule."
  @spec once(t(), Term.t()) :: {:ok, Term.t(), Rule.t()} | :not_found
  def once(%__MODULE__{rules: rules}, term) do
    Enum.find_value(rules, :not_found, fn rule ->
      case Rewrite.once_rule(term, rule.rewrite) do
        {:ok, term} -> {:ok, term, rule}
        :not_found -> false
      end
    end)
  end
end
