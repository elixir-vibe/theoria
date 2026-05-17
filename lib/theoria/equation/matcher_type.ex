defmodule Theoria.Equation.MatcherType do
  @moduledoc "Internal builder for checked matcher declaration types and bodies for supported fragments."

  alias Theoria.Equation.MatcherDescriptor
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
  def alternatives(%Schema{} = schema, %MatcherInfo{} = info) do
    case MatcherDescriptor.from_schema(schema, info) do
      {:ok, descriptor} -> Enum.map(descriptor.alternatives, &alternative_from_descriptor/1)
      {:error, _reason} -> []
    end
  end

  @doc "Builds a matcher type for supported schemas."
  @spec build(Schema.t(), MatcherInfo.t()) :: {:ok, Term.t()} | {:error, term()}
  def build(%Schema{} = schema, %MatcherInfo{} = info) do
    with {:ok, descriptor} <- MatcherDescriptor.from_schema(schema, info) do
      from_descriptor(descriptor)
    end
  end

  @doc "Builds a matcher type from a descriptor."
  @spec from_descriptor(MatcherDescriptor.t()) :: {:ok, Term.t()} | {:error, term()}
  def from_descriptor(%MatcherDescriptor{family: :bool, discriminants: [_, _]}),
    do: {:ok, bool_binary_type()}

  def from_descriptor(%MatcherDescriptor{family: :bool}), do: {:ok, bool_type()}
  def from_descriptor(%MatcherDescriptor{family: :nat}), do: {:ok, nat_type()}
  def from_descriptor(%MatcherDescriptor{family: :list}), do: {:ok, list_type()}

  def from_descriptor(%MatcherDescriptor{family: family}),
    do: {:error, {:unsupported_matcher_type, family}}

  @doc "Builds a matcher value for supported schemas."
  @spec value(Schema.t(), MatcherInfo.t()) :: {:ok, Term.t()} | {:error, term()}
  def value(%Schema{} = schema, %MatcherInfo{} = info) do
    with {:ok, descriptor} <- MatcherDescriptor.from_schema(schema, info) do
      value_from_descriptor(descriptor)
    end
  end

  @doc "Builds a matcher body from a descriptor."
  @spec value_from_descriptor(MatcherDescriptor.t()) :: {:ok, Term.t()} | {:error, term()}
  def value_from_descriptor(%MatcherDescriptor{family: :bool, discriminants: [_, _]}),
    do: {:ok, bool_binary_value()}

  def value_from_descriptor(%MatcherDescriptor{family: :bool}), do: {:ok, bool_value()}
  def value_from_descriptor(%MatcherDescriptor{family: :nat}), do: {:ok, nat_value()}
  def value_from_descriptor(%MatcherDescriptor{family: :list}), do: {:ok, list_value()}

  def value_from_descriptor(%MatcherDescriptor{family: family}),
    do: {:error, {:unsupported_matcher_value, family}}

  defp alternative_from_descriptor(%MatcherDescriptor.Alternative{} = alternative) do
    %Alternative{
      constructor: alternative.name,
      fields: alternative.fields,
      result_type: alternative.result
    }
  end

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
