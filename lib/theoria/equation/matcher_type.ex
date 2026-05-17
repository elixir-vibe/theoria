defmodule Theoria.Equation.MatcherType do
  @moduledoc "Builds checked matcher declaration types and bodies for supported fragments."

  alias Theoria.Equation.MatcherInfo
  alias Theoria.Equation.Recursors
  alias Theoria.Equation.Schema
  alias Theoria.Term

  defmodule Alternative do
    @moduledoc "Matcher branch type descriptor."

    alias Theoria.Term

    @enforce_keys [:constructor, :fields, :result_type]
    defstruct [:constructor, :fields, :result_type]

    @type t :: %__MODULE__{
            constructor: atom() | boolean(),
            fields: [{atom(), Term.t()}],
            result_type: Term.t()
          }
  end

  @doc "Returns branch descriptors for the matcher alternatives in a schema."
  @spec alternatives(Schema.t(), MatcherInfo.t()) :: [Alternative.t()]
  def alternatives(%Schema{family: :bool}, %MatcherInfo{} = info) do
    Enum.map(info.alternatives, fn alternative ->
      %Alternative{constructor: alternative.constructor, fields: [], result_type: Term.bvar(1)}
    end)
  end

  @doc "Builds a matcher type for supported schemas."
  @spec build(Schema.t(), MatcherInfo.t()) :: {:ok, Term.t()} | {:error, term()}
  def build(%Schema{family: :bool}, %MatcherInfo{}) do
    {:ok, bool_type()}
  end

  def build(%Schema{family: family}, %MatcherInfo{}),
    do: {:error, {:unsupported_matcher_type, family}}

  @doc "Builds a matcher value for supported schemas."
  @spec value(Schema.t(), MatcherInfo.t()) :: {:ok, Term.t()} | {:error, term()}
  def value(%Schema{family: :bool}, %MatcherInfo{}) do
    {:ok, bool_value()}
  end

  def value(%Schema{family: family}, %MatcherInfo{}),
    do: {:error, {:unsupported_matcher_value, family}}

  defp bool_type do
    Term.forall(
      :motive,
      Term.sort(1),
      Term.forall(
        :b,
        Term.const(:Bool),
        Term.forall(:on_true, Term.bvar(1), Term.forall(:on_false, Term.bvar(2), Term.bvar(3)))
      )
    )
  end

  defp bool_value do
    Term.lam(
      :motive,
      Term.sort(1),
      Term.lam(
        :b,
        Term.const(:Bool),
        Term.lam(
          :on_true,
          Term.bvar(1),
          Term.lam(
            :on_false,
            Term.bvar(2),
            Recursors.bool_rec(Term.bvar(3), Term.bvar(1), Term.bvar(0), Term.bvar(2))
          )
        )
      )
    )
  end
end
