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

    @enforce_keys [:constructor, :fields, :result_type, :binder_name, :binder_type]
    defstruct [:constructor, :fields, :result_type, :binder_name, :binder_type]

    @type t :: %__MODULE__{
            constructor: atom() | boolean(),
            fields: [Descriptor.Field.t()],
            result_type: Term.t(),
            binder_name: atom(),
            binder_type: Term.t()
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
    descriptor.alternatives
    |> Enum.with_index()
    |> Enum.map(fn {alternative, position} ->
      alternative_from_descriptor(descriptor, alternative, position)
    end)
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
    alternatives = alternatives_from_descriptor(descriptor)

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
         alternatives: alternatives,
         alternative_binders: Enum.map(alternatives, &{&1.binder_name, &1.binder_type}),
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

  defp alternative_from_descriptor(
         %MatcherDescriptor{} = descriptor,
         %MatcherDescriptor.Alternative{} = alternative,
         position
       ) do
    %Alternative{
      constructor: alternative.name,
      fields: alternative.fields,
      result_type: alternative.result,
      binder_name: alternative_binder_name(alternative),
      binder_type: alternative_binder_type(descriptor, alternative, position)
    }
  end

  defp simple_shape_plan(%MatcherDescriptor{family: :bool, discriminants: [_, _]}) do
    {:ok,
     [
       motive_type: Term.sort(1),
       discriminant_binders: [a: Term.const(:Bool), b: Term.const(:Bool)],
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

  defp alternative_binder_name(%MatcherDescriptor.Alternative{name: true}), do: :on_true
  defp alternative_binder_name(%MatcherDescriptor.Alternative{name: false}), do: :on_false
  defp alternative_binder_name(%MatcherDescriptor.Alternative{name: :zero}), do: :on_zero
  defp alternative_binder_name(%MatcherDescriptor.Alternative{name: :succ}), do: :on_succ
  defp alternative_binder_name(%MatcherDescriptor.Alternative{name: :list_nil}), do: :on_nil
  defp alternative_binder_name(%MatcherDescriptor.Alternative{name: :list_cons}), do: :on_cons

  defp alternative_binder_name(%MatcherDescriptor.Alternative{name: name}) when is_atom(name),
    do: String.to_atom("on_#{name}")

  defp alternative_binder_type(
         %MatcherDescriptor{family: :bool, discriminants: [_, _]},
         _alternative,
         position
       ),
       do: Term.bvar(position + 2)

  defp alternative_binder_type(%MatcherDescriptor{family: :bool}, _alternative, position),
    do: Term.bvar(position + 1)

  defp alternative_binder_type(%MatcherDescriptor{family: :nat}, %{name: :zero}, _position),
    do: Term.bvar(1)

  defp alternative_binder_type(
         %MatcherDescriptor{family: :nat},
         %{name: :succ} = alternative,
         _position
       ),
       do: simple_case_telescope(alternative, Term.bvar(3), Term.bvar(4))

  defp alternative_binder_type(%MatcherDescriptor{family: :list}, %{name: :list_nil}, _position),
    do: Term.bvar(1)

  defp alternative_binder_type(%MatcherDescriptor{family: :list}, %{name: :list_cons}, _position),
    do: list_cons_case_type()

  defp alternative_binder_type(_descriptor, alternative, _position), do: alternative.result

  defp simple_case_telescope(alternative, recursive_type, result) do
    recursive_fields =
      case alternative.recursive_fields do
        [] -> Enum.map(alternative.recursive_hypotheses, fn {name, _type} -> %{name: name} end)
        fields -> fields
      end

    alternative.fields
    |> Enum.map(&{:_, &1.type})
    |> Kernel.++(Enum.map(recursive_fields, fn _field -> {:_, recursive_type} end))
    |> forall_telescope(result)
  end

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
