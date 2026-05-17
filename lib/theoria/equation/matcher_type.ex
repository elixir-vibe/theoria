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

  def alternatives(%Schema{family: :nat}, %MatcherInfo{} = info) do
    Enum.map(info.alternatives, fn
      %{constructor: :zero} ->
        %Alternative{constructor: :zero, fields: [], result_type: Term.bvar(1)}

      %{constructor: :succ} ->
        %Alternative{
          constructor: :succ,
          fields: [{:pred, Term.const(:Nat)}],
          result_type: Term.bvar(2)
        }
    end)
  end

  def alternatives(%Schema{family: :list}, %MatcherInfo{} = info) do
    Enum.map(info.alternatives, fn
      %{constructor: :list_nil} ->
        %Alternative{constructor: :list_nil, fields: [], result_type: Term.bvar(1)}

      %{constructor: :list_cons} ->
        %Alternative{
          constructor: :list_cons,
          fields: [{:head, Term.bvar(0)}, {:tail, list_of(Term.bvar(0))}],
          result_type: Term.bvar(2)
        }
    end)
  end

  @doc "Builds a matcher type for supported schemas."
  @spec build(Schema.t(), MatcherInfo.t()) :: {:ok, Term.t()} | {:error, term()}
  def build(%Schema{family: :bool}, %MatcherInfo{num_discriminants: 2}),
    do: {:ok, bool_binary_type()}

  def build(%Schema{family: :bool}, %MatcherInfo{}), do: {:ok, bool_type()}
  def build(%Schema{family: :nat}, %MatcherInfo{}), do: {:ok, nat_type()}
  def build(%Schema{family: :list}, %MatcherInfo{}), do: {:ok, list_type()}

  def build(%Schema{family: family}, %MatcherInfo{}),
    do: {:error, {:unsupported_matcher_type, family}}

  @doc "Builds a matcher value for supported schemas."
  @spec value(Schema.t(), MatcherInfo.t()) :: {:ok, Term.t()} | {:error, term()}
  def value(%Schema{family: :bool}, %MatcherInfo{num_discriminants: 2}),
    do: {:ok, bool_binary_value()}

  def value(%Schema{family: :bool}, %MatcherInfo{}), do: {:ok, bool_value()}
  def value(%Schema{family: :nat}, %MatcherInfo{}), do: {:ok, nat_value()}
  def value(%Schema{family: :list}, %MatcherInfo{}), do: {:ok, list_value()}

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

  defp bool_binary_type do
    motive = Term.sort(1)
    result = Term.bvar(6)

    Term.forall(
      :motive,
      motive,
      Term.forall(
        :a,
        Term.const(:Bool),
        Term.forall(
          :b,
          Term.const(:Bool),
          Term.forall(
            :on_true_true,
            Term.bvar(2),
            Term.forall(
              :on_true_false,
              Term.bvar(3),
              Term.forall(
                :on_false_true,
                Term.bvar(4),
                Term.forall(:on_false_false, Term.bvar(5), result)
              )
            )
          )
        )
      )
    )
  end

  defp bool_binary_value do
    Term.lam(
      :motive,
      Term.sort(1),
      Term.lam(
        :a,
        Term.const(:Bool),
        Term.lam(
          :b,
          Term.const(:Bool),
          Term.lam(
            :on_true_true,
            Term.bvar(2),
            Term.lam(
              :on_true_false,
              Term.bvar(3),
              Term.lam(
                :on_false_true,
                Term.bvar(4),
                Term.lam(
                  :on_false_false,
                  Term.bvar(5),
                  bool_binary_body()
                )
              )
            )
          )
        )
      )
    )
  end

  defp bool_binary_body do
    motive = Term.bvar(6)
    second_discriminant = Term.bvar(4)

    Recursors.bool_rec(
      motive,
      Recursors.bool_rec(motive, Term.bvar(3), Term.bvar(2), second_discriminant),
      Recursors.bool_rec(motive, Term.bvar(1), Term.bvar(0), second_discriminant),
      Term.bvar(5)
    )
  end

  defp nat_type do
    succ_case_type =
      Term.forall(:_, Term.const(:Nat), Term.forall(:_, Term.bvar(3), Term.bvar(4)))

    Term.forall(
      :motive,
      Term.sort(1),
      Term.forall(
        :n,
        Term.const(:Nat),
        Term.forall(:on_zero, Term.bvar(1), Term.forall(:on_succ, succ_case_type, Term.bvar(3)))
      )
    )
  end

  defp nat_value do
    succ_case_type =
      Term.forall(:_, Term.const(:Nat), Term.forall(:_, Term.bvar(3), Term.bvar(4)))

    Term.lam(
      :motive,
      Term.sort(1),
      Term.lam(
        :n,
        Term.const(:Nat),
        Term.lam(
          :on_zero,
          Term.bvar(1),
          Term.lam(
            :on_succ,
            succ_case_type,
            Recursors.nat_rec(Term.bvar(3), Term.bvar(1), Term.bvar(0), Term.bvar(2))
          )
        )
      )
    )
  end

  defp list_type do
    type = Term.sort(1)
    motive = Term.bvar(1)

    Term.forall(
      :a,
      type,
      Term.forall(
        :motive,
        type,
        Term.forall(
          :xs,
          list_of(motive),
          Term.forall(:on_nil, motive, Term.forall(:on_cons, list_cons_case_type(), Term.bvar(3)))
        )
      )
    )
  end

  defp list_value do
    type = Term.sort(1)
    motive = Term.bvar(1)

    Term.lam(
      :a,
      type,
      Term.lam(
        :motive,
        type,
        Term.lam(
          :xs,
          list_of(motive),
          Term.lam(
            :on_nil,
            motive,
            Term.lam(
              :on_cons,
              list_cons_case_type(),
              Recursors.list_rec(
                Term.bvar(4),
                Term.bvar(3),
                Term.bvar(1),
                Term.bvar(0),
                Term.bvar(2)
              )
            )
          )
        )
      )
    )
  end

  defp list_cons_case_type do
    element_type = Term.bvar(4)

    Term.forall(
      :_,
      Term.bvar(3),
      Term.forall(:_, list_of(element_type), Term.forall(:_, element_type, Term.bvar(5)))
    )
  end

  defp list_of(element_type), do: Term.app(Term.const(:List, [1]), element_type)
end
