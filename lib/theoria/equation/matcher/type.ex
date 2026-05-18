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

    @enforce_keys [
      :family,
      :parameters,
      :indexed?,
      :motive_name,
      :motive_type,
      :discriminants,
      :discriminant_binders,
      :alternatives,
      :alternative_binders,
      :result,
      :body,
      :recursor
    ]
    defstruct [
      :family,
      :parameters,
      :indexed?,
      :motive_name,
      :motive_type,
      :discriminants,
      :discriminant_binders,
      :alternatives,
      :alternative_binders,
      :result,
      :body,
      :recursor
    ]

    @type t :: %__MODULE__{
            family: atom(),
            parameters: keyword(),
            indexed?: boolean(),
            motive_name: atom(),
            motive_type: Term.t(),
            discriminants: [MatcherInfo.Discriminant.t()],
            discriminant_binders: keyword(),
            alternatives: [Alternative.t()],
            alternative_binders: keyword(),
            result: Term.t(),
            body: Term.t(),
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

  @doc "Plans matcher declaration binders and body from a descriptor."
  @spec shape_from_descriptor(MatcherDescriptor.t()) :: {:ok, Shape.t()} | {:error, term()}
  def shape_from_descriptor(%MatcherDescriptor{indexed?: true, family: family}),
    do: {:error, {:unsupported_indexed_matcher_shape, family}}

  def shape_from_descriptor(%MatcherDescriptor{} = descriptor) do
    with {:ok, plan} <- simple_shape_plan(descriptor) do
      {:ok,
       %Shape{
         family: descriptor.family,
         parameters: descriptor.parameters,
         indexed?: descriptor.indexed?,
         motive_name: :motive,
         motive_type: Keyword.fetch!(plan, :motive_type),
         discriminants: descriptor.discriminants,
         discriminant_binders: Keyword.fetch!(plan, :discriminant_binders),
         alternatives: alternatives_from_descriptor(descriptor),
         alternative_binders: Keyword.fetch!(plan, :alternative_binders),
         result: Keyword.fetch!(plan, :result),
         body: Keyword.fetch!(plan, :body),
         recursor: descriptor.recursor
       }}
    end
  end

  defp simple_type_from_shape(%Shape{} = shape) do
    {:ok, forall_telescope(binders(shape), shape.result)}
  end

  defp simple_value_from_shape(%Shape{} = shape) do
    {:ok, lam_telescope(binders(shape), shape.body)}
  end

  defp alternative_from_descriptor(%MatcherDescriptor.Alternative{} = alternative) do
    %Alternative{
      constructor: alternative.name,
      fields: alternative.fields,
      result_type: alternative.result
    }
  end

  defp simple_shape_plan(%MatcherDescriptor{family: :bool, discriminants: [_, _]}) do
    {:ok,
     [
       motive_type: Term.sort(1),
       discriminant_binders: [a: Term.const(:Bool), b: Term.const(:Bool)],
       alternative_binders: [
         on_true_true: Term.bvar(2),
         on_true_false: Term.bvar(3),
         on_false_true: Term.bvar(4),
         on_false_false: Term.bvar(5)
       ],
       result: Term.bvar(6),
       body: bool_binary_body()
     ]}
  end

  defp simple_shape_plan(%MatcherDescriptor{family: :bool}) do
    result = Term.bvar(3)

    {:ok,
     [
       motive_type: Term.sort(1),
       discriminant_binders: [b: Term.const(:Bool)],
       alternative_binders: [on_true: Term.bvar(1), on_false: Term.bvar(2)],
       result: result,
       body:
         RecursorApplication.bool_rec(
           result,
           Term.bvar(1),
           Term.bvar(0),
           Term.bvar(2)
         )
     ]}
  end

  defp simple_shape_plan(%MatcherDescriptor{family: :nat}) do
    result = Term.bvar(3)
    on_zero = Term.bvar(1)

    {:ok,
     [
       motive_type: Term.sort(1),
       discriminant_binders: [n: Term.const(:Nat)],
       alternative_binders: [on_zero: on_zero, on_succ: nat_succ_case_type()],
       result: result,
       body:
         RecursorApplication.nat_rec(
           result,
           on_zero,
           Term.bvar(0),
           Term.bvar(2)
         )
     ]}
  end

  defp simple_shape_plan(%MatcherDescriptor{family: :list}) do
    motive = Term.bvar(1)

    {:ok,
     [
       motive_type: Term.sort(1),
       discriminant_binders: [xs: list_of(motive)],
       alternative_binders: [on_nil: motive, on_cons: list_cons_case_type()],
       result: Term.bvar(3),
       body:
         RecursorApplication.list_rec(
           Term.bvar(4),
           Term.bvar(3),
           Term.bvar(1),
           Term.bvar(0),
           Term.bvar(2)
         )
     ]}
  end

  defp simple_shape_plan(%MatcherDescriptor{family: family}),
    do: {:error, {:unsupported_matcher_shape, family}}

  defp binders(%Shape{} = shape) do
    shape.parameters ++
      [{shape.motive_name, shape.motive_type}] ++
      shape.discriminant_binders ++ shape.alternative_binders
  end

  defp forall_telescope(binders, result) do
    Enum.reduce(Enum.reverse(binders), result, fn {name, type}, body ->
      Term.forall(name, type, body)
    end)
  end

  defp lam_telescope(binders, body) do
    Enum.reduce(Enum.reverse(binders), body, fn {name, type}, acc ->
      Term.lam(name, type, acc)
    end)
  end

  defp nat_succ_case_type do
    Term.forall(:_, Term.const(:Nat), Term.forall(:_, Term.bvar(3), Term.bvar(4)))
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
