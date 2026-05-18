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
    defstruct [
      :constructor,
      :fields,
      :result_type,
      :binder_name,
      :binder_type,
      index_patterns: [],
      motive_arguments: [],
      case_result: nil
    ]

    @type t :: %__MODULE__{
            constructor: atom() | boolean(),
            fields: [Descriptor.Field.t()],
            result_type: Term.t(),
            binder_name: atom(),
            binder_type: Term.t(),
            index_patterns: [Term.t()],
            motive_arguments: [Term.t()],
            case_result: Term.t() | nil
          }
  end

  defmodule Shape do
    @moduledoc "Planned matcher declaration shape derived from a matcher descriptor."

    @enforce_keys [
      :family,
      :parameters,
      :indexed?,
      :indices,
      :index_binders,
      :index_patterns,
      :motive_name,
      :motive_type,
      :motive_binders,
      :motive_arguments,
      :motive_result,
      :discriminants,
      :discriminant_binders,
      :alternatives,
      :alternative_binders,
      :result,
      :recursor_arguments,
      :body,
      :recursor
    ]
    defstruct [
      :family,
      :parameters,
      :indexed?,
      :indices,
      :index_binders,
      :index_patterns,
      :motive_name,
      :motive_type,
      :motive_binders,
      :motive_arguments,
      :motive_result,
      :discriminants,
      :discriminant_binders,
      :alternatives,
      :alternative_binders,
      :result,
      :recursor_arguments,
      :body,
      :recursor
    ]

    @type t :: %__MODULE__{
            family: atom(),
            parameters: keyword(),
            indexed?: boolean(),
            indices: keyword(),
            index_binders: keyword(),
            index_patterns: %{optional(atom() | boolean()) => [Term.t()]},
            motive_name: atom(),
            motive_type: Term.t(),
            motive_binders: keyword(),
            motive_arguments: [Term.t()],
            motive_result: Term.t(),
            discriminants: [MatcherInfo.Discriminant.t()],
            discriminant_binders: keyword(),
            alternatives: [Alternative.t()],
            alternative_binders: keyword(),
            result: Term.t(),
            recursor_arguments: [Term.t()],
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
  def value_from_descriptor(%MatcherDescriptor{} = descriptor) do
    with {:ok, shape} <- shape_from_descriptor(descriptor) do
      simple_value_from_shape(shape)
    end
  end

  @doc "Plans matcher declaration binders and body from a descriptor."
  @spec shape_from_descriptor(MatcherDescriptor.t()) :: {:ok, Shape.t()} | {:error, term()}
  def shape_from_descriptor(%MatcherDescriptor{} = descriptor) do
    alternatives = alternatives_from_descriptor(descriptor)

    with {:ok, plan} <- shape_plan(descriptor) do
      shape = %Shape{
        family: descriptor.family,
        parameters: descriptor.parameters,
        indexed?: descriptor.indexed?,
        indices: descriptor.indices,
        index_binders: descriptor.indices,
        index_patterns: index_patterns(descriptor),
        motive_name: :motive,
        motive_type: Keyword.fetch!(plan, :motive_type),
        motive_binders: Keyword.get(plan, :motive_binders, []),
        motive_arguments: [],
        motive_result: Term.const(:unplanned_motive_result),
        discriminants: descriptor.discriminants,
        discriminant_binders: Keyword.fetch!(plan, :discriminant_binders),
        alternatives: alternatives,
        alternative_binders: Enum.map(alternatives, &{&1.binder_name, &1.binder_type}),
        result: Keyword.fetch!(plan, :result),
        recursor_arguments: [],
        body: Term.const(:unplanned_matcher_body),
        recursor: descriptor.recursor
      }

      shape = plan_motive_result(shape)
      shape = plan_indexed_alternatives(shape)
      recursor_arguments = recursor_arguments(shape)
      shape_with_arguments = %{shape | recursor_arguments: recursor_arguments}

      {:ok, %{shape_with_arguments | body: body_from_shape(shape_with_arguments)}}
    end
  end

  defp simple_type_from_shape(%Shape{indexed?: true, family: family}),
    do: {:error, {:unsupported_indexed_matcher_type, family}}

  defp simple_type_from_shape(%Shape{} = shape) do
    {:ok, forall_telescope(binders(shape), shape.result)}
  end

  defp simple_value_from_shape(%Shape{indexed?: true, family: family}),
    do: {:error, {:unsupported_indexed_matcher_value, family}}

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
      binder_type: alternative_binder_type(descriptor, alternative, position),
      index_patterns: alternative.index_patterns,
      motive_arguments: [],
      case_result: alternative.result
    }
  end

  defp shape_plan(%MatcherDescriptor{indexed?: true} = descriptor),
    do: indexed_shape_plan(descriptor)

  defp shape_plan(%MatcherDescriptor{} = descriptor), do: simple_shape_plan(descriptor)

  defp simple_shape_plan(%MatcherDescriptor{family: :bool, discriminants: [_, _]}) do
    {:ok,
     [
       motive_type: Term.sort(1),
       discriminant_binders: [a: Term.const(:Bool), b: Term.const(:Bool)],
       result: Term.bvar(6)
     ]}
  end

  defp simple_shape_plan(%MatcherDescriptor{family: :bool}) do
    result = Term.bvar(3)

    {:ok,
     [
       motive_type: Term.sort(1),
       discriminant_binders: [b: Term.const(:Bool)],
       result: result
     ]}
  end

  defp simple_shape_plan(%MatcherDescriptor{family: :nat}) do
    result = Term.bvar(3)

    {:ok,
     [
       motive_type: Term.sort(1),
       discriminant_binders: [n: Term.const(:Nat)],
       result: result
     ]}
  end

  defp simple_shape_plan(%MatcherDescriptor{family: :list}) do
    motive = Term.bvar(1)

    {:ok,
     [
       motive_type: Term.sort(1),
       discriminant_binders: [xs: list_of(motive)],
       result: Term.bvar(3)
     ]}
  end

  defp simple_shape_plan(%MatcherDescriptor{family: family}),
    do: {:error, {:unsupported_matcher_shape, family}}

  defp indexed_shape_plan(%MatcherDescriptor{family: :Vec}) do
    index_type = Term.const(:Nat)
    index = Term.bvar(0)
    parameter = Term.bvar(2)
    vec_at_index = Term.const(:Vec) |> Term.app(parameter) |> Term.app(index)

    {:ok,
     [
       motive_type: Term.sort(1),
       motive_binders: [n: index_type, xs: vec_at_index],
       discriminant_binders: [xs: vec_at_index],
       result: Term.const(:unsupported_indexed_matcher_result)
     ]}
  end

  defp indexed_shape_plan(%MatcherDescriptor{family: family}),
    do: {:error, {:unsupported_indexed_matcher_shape, family}}

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

  defp alternative_binder_type(%MatcherDescriptor{indexed?: true}, alternative, _position) do
    indexed_case_telescope(alternative)
  end

  defp alternative_binder_type(_descriptor, alternative, _position), do: alternative.result

  defp indexed_case_telescope(alternative),
    do: indexed_case_telescope(alternative, Term.const(:unsupported_indexed_case))

  defp indexed_case_telescope(alternative, result) do
    alternative.fields
    |> Enum.map(&{:_, &1.type})
    |> forall_telescope(result)
  end

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

  defp plan_motive_result(%Shape{indexed?: false} = shape) do
    %{shape | motive_arguments: [], motive_result: shape.result}
  end

  defp plan_motive_result(%Shape{indexed?: true} = shape) do
    motive_arguments =
      Enum.map(shape.motive_binders, fn {name, _type} -> binder_ref(shape, name) end)

    motive_result = apply_motive(binder_ref(shape, shape.motive_name), motive_arguments)

    %{
      shape
      | motive_arguments: motive_arguments,
        motive_result: motive_result,
        result: motive_result
    }
  end

  defp plan_indexed_alternatives(%Shape{indexed?: false} = shape), do: shape

  defp plan_indexed_alternatives(%Shape{indexed?: true} = shape) do
    alternatives =
      Enum.map(shape.alternatives, fn alternative ->
        motive_arguments = alternative.index_patterns ++ [constructor_application(alternative)]
        case_result = apply_motive(binder_ref(shape, shape.motive_name), motive_arguments)

        %{
          alternative
          | motive_arguments: motive_arguments,
            case_result: case_result,
            binder_type: indexed_case_telescope(alternative, case_result)
        }
      end)

    %{
      shape
      | alternatives: alternatives,
        alternative_binders: Enum.map(alternatives, &{&1.binder_name, &1.binder_type})
    }
  end

  defp constructor_application(%Alternative{} = alternative) do
    alternative.fields
    |> Enum.map(&Term.bvar(length(alternative.fields) - &1.position - 1))
    |> Enum.reduce(Term.const(alternative.constructor), fn argument, term ->
      Term.app(term, argument)
    end)
  end

  defp apply_motive(motive, arguments), do: Enum.reduce(arguments, motive, &Term.app(&2, &1))

  defp recursor_arguments(%Shape{indexed?: true}), do: []

  defp recursor_arguments(%Shape{family: :bool, discriminants: [_, _]} = shape) do
    [
      binder_ref(shape, :motive),
      binder_ref(shape, :a),
      binder_ref(shape, :b),
      binder_ref(shape, :on_true_true),
      binder_ref(shape, :on_true_false),
      binder_ref(shape, :on_false_true),
      binder_ref(shape, :on_false_false)
    ]
  end

  defp recursor_arguments(%Shape{family: :bool} = shape) do
    [
      binder_ref(shape, :motive),
      binder_ref(shape, :on_true),
      binder_ref(shape, :on_false),
      binder_ref(shape, :b)
    ]
  end

  defp recursor_arguments(%Shape{family: :nat} = shape) do
    [
      binder_ref(shape, :motive),
      binder_ref(shape, :on_zero),
      binder_ref(shape, :on_succ),
      binder_ref(shape, :n)
    ]
  end

  defp recursor_arguments(%Shape{family: :list} = shape) do
    [
      binder_ref(shape, :a),
      binder_ref(shape, :motive),
      binder_ref(shape, :on_nil),
      binder_ref(shape, :on_cons),
      binder_ref(shape, :xs)
    ]
  end

  defp body_from_shape(%Shape{indexed?: true}), do: Term.const(:unsupported_indexed_matcher_body)

  defp body_from_shape(%Shape{family: :bool, discriminants: [_, _]} = shape) do
    bool_binary_body(shape)
  end

  defp body_from_shape(%Shape{} = shape) do
    apply_recursor!(shape.recursor, shape.recursor_arguments)
  end

  defp apply_recursor!(recursor, arguments) do
    case RecursorApplication.build(recursor, arguments) do
      {:ok, term} -> term
      {:error, reason} -> raise ArgumentError, "invalid recursor application: #{inspect(reason)}"
    end
  end

  defp binder_ref(%Shape{} = shape, name) do
    binders = shape_binders(shape)
    index = Enum.find_index(binders, &(elem(&1, 0) == name))

    if is_nil(index) do
      raise ArgumentError, "unknown matcher binder #{inspect(name)}"
    end

    Term.bvar(length(binders) - index - 1)
  end

  defp binders(%Shape{} = shape), do: shape_binders(shape)

  defp shape_binders(%Shape{} = shape) do
    shape.parameters ++
      [{shape.motive_name, shape.motive_type}] ++
      shape.index_binders ++ shape.discriminant_binders ++ shape.alternative_binders
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

  defp bool_binary_body(%Shape{} = shape) do
    motive = binder_ref(shape, :motive)
    second_discriminant = binder_ref(shape, :b)

    RecursorApplication.bool_rec(
      motive,
      RecursorApplication.bool_rec(
        motive,
        binder_ref(shape, :on_true_true),
        binder_ref(shape, :on_true_false),
        second_discriminant
      ),
      RecursorApplication.bool_rec(
        motive,
        binder_ref(shape, :on_false_true),
        binder_ref(shape, :on_false_false),
        second_discriminant
      ),
      binder_ref(shape, :a)
    )
  end

  defp index_patterns(%MatcherDescriptor{} = descriptor) do
    Map.new(descriptor.alternatives, &{&1.name, &1.index_patterns})
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
