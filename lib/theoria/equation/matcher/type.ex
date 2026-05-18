defmodule Theoria.Equation.Matcher.Type do
  @moduledoc "Experimental/internal API for 0.2; subject to change before 0.3. Internal builder for checked matcher declaration types and bodies for supported fragments."

  alias Theoria.Equation.Matcher.Descriptor, as: MatcherDescriptor
  alias Theoria.Equation.Matcher.Info, as: MatcherInfo
  alias Theoria.Equation.Recursor.Application, as: RecursorApplication
  alias Theoria.Equation.Schema
  alias Theoria.Term

  defmodule Alternative do
    @moduledoc "Matcher branch type descriptor."

    alias Theoria.Term

    alias Theoria.Equation.Matcher.Descriptor

    @enforce_keys [:constructor, :fields, :result_type]
    defstruct [:constructor, :fields, :result_type]

    @type t :: %__MODULE__{
            constructor: atom() | boolean(),
            fields: [Descriptor.Field.t()],
            result_type: Term.t()
          }
  end

  defmodule Shape do
    @moduledoc "Planned matcher declaration shape derived from a matcher descriptor."

    @enforce_keys [:family, :parameters, :discriminants, :alternatives, :result, :recursor]
    defstruct [:family, :parameters, :discriminants, :alternatives, :result, :recursor]

    @type t :: %__MODULE__{
            family: atom(),
            parameters: keyword(),
            discriminants: [MatcherInfo.Discriminant.t()],
            alternatives: [Alternative.t()],
            result: Term.t(),
            recursor: atom()
          }
  end

  @doc "Returns branch descriptors for the matcher alternatives in a schema."
  @spec alternatives(Schema.t(), MatcherInfo.t()) :: [Alternative.t()]
  def alternatives(%Schema{} = schema, %MatcherInfo{} = info) do
    case MatcherDescriptor.from_schema(schema, info) do
      {:ok, descriptor} -> alternatives_from_descriptor(descriptor)
      {:error, _reason} -> []
    end
  end

  @doc "Returns branch descriptors from a matcher descriptor."
  @spec alternatives_from_descriptor(MatcherDescriptor.t()) :: [Alternative.t()]
  def alternatives_from_descriptor(%MatcherDescriptor{} = descriptor) do
    Enum.map(descriptor.alternatives, &alternative_from_descriptor/1)
  end

  @doc "Builds a matcher type for supported schemas."
  @spec build(Schema.t(), MatcherInfo.t()) :: {:ok, Term.t()} | {:error, term()}
  def build(%Schema{} = schema, %MatcherInfo{} = info) do
    with {:ok, descriptor} <- MatcherDescriptor.from_schema(schema, info) do
      from_descriptor(descriptor)
    end
  end

  @doc "Builds a matcher type from a descriptor."
  @spec from_descriptor(MatcherDescriptor.t()) ::
          {:ok, Term.t()} | {:error, term()}
  def from_descriptor(%MatcherDescriptor{indexed?: true, family: family}),
    do: {:error, {:unsupported_indexed_matcher_type, family}}

  def from_descriptor(%MatcherDescriptor{} = descriptor) do
    with {:ok, shape} <- shape_from_descriptor(descriptor) do
      simple_type_from_shape(shape)
    end
  end

  @doc "Builds a matcher value for supported schemas."
  @spec value(Schema.t(), MatcherInfo.t()) :: {:ok, Term.t()} | {:error, term()}
  def value(%Schema{} = schema, %MatcherInfo{} = info) do
    with {:ok, descriptor} <- MatcherDescriptor.from_schema(schema, info) do
      value_from_descriptor(descriptor)
    end
  end

  @doc "Builds a matcher body from a descriptor."
  @spec value_from_descriptor(MatcherDescriptor.t()) ::
          {:ok, Term.t()} | {:error, term()}
  def value_from_descriptor(%MatcherDescriptor{indexed?: true, family: family}),
    do: {:error, {:unsupported_indexed_matcher_value, family}}

  def value_from_descriptor(%MatcherDescriptor{} = descriptor) do
    with {:ok, shape} <- shape_from_descriptor(descriptor) do
      simple_value_from_shape(shape)
    end
  end

  defp shape_from_descriptor(%MatcherDescriptor{} = descriptor) do
    {:ok,
     %Shape{
       family: descriptor.family,
       parameters: descriptor.parameters,
       discriminants: descriptor.discriminants,
       alternatives: alternatives_from_descriptor(descriptor),
       result: descriptor.result,
       recursor: descriptor.recursor
     }}
  end

  defp simple_type_from_shape(%Shape{family: :bool, discriminants: [_, _]}),
    do: {:ok, bool_binary_type()}

  defp simple_type_from_shape(%Shape{family: :bool}), do: {:ok, bool_type()}
  defp simple_type_from_shape(%Shape{family: :nat}), do: {:ok, nat_type()}
  defp simple_type_from_shape(%Shape{family: :list}), do: {:ok, list_type()}

  defp simple_type_from_shape(%Shape{family: family}),
    do: {:error, {:unsupported_matcher_type, family}}

  defp simple_value_from_shape(%Shape{family: :bool, discriminants: [_, _]}),
    do: {:ok, bool_binary_value()}

  defp simple_value_from_shape(%Shape{family: :bool}), do: {:ok, bool_value()}
  defp simple_value_from_shape(%Shape{family: :nat}), do: {:ok, nat_value()}
  defp simple_value_from_shape(%Shape{family: :list}), do: {:ok, list_value()}

  defp simple_value_from_shape(%Shape{family: family}),
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
            RecursorApplication.bool_rec(
              Term.bvar(3),
              Term.bvar(1),
              Term.bvar(0),
              Term.bvar(2)
            )
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

    RecursorApplication.bool_rec(
      motive,
      RecursorApplication.bool_rec(
        motive,
        Term.bvar(3),
        Term.bvar(2),
        second_discriminant
      ),
      RecursorApplication.bool_rec(
        motive,
        Term.bvar(1),
        Term.bvar(0),
        second_discriminant
      ),
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
            RecursorApplication.nat_rec(
              Term.bvar(3),
              Term.bvar(1),
              Term.bvar(0),
              Term.bvar(2)
            )
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
              RecursorApplication.list_rec(
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
