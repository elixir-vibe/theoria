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
      :recursor,
      :recursor_descriptor
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
      :recursor,
      :recursor_descriptor
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
            recursor: atom(),
            recursor_descriptor: Theoria.Equation.Recursor.Descriptor.t() | nil
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

  @doc "Experimentally emits an indexed matcher type term without enabling checked matcher declarations."
  @spec indexed_from_descriptor(MatcherDescriptor.t()) :: {:ok, Term.t()} | {:error, term()}
  def indexed_from_descriptor(%MatcherDescriptor{indexed?: false, family: family}),
    do: {:error, {:not_indexed_matcher_type, family}}

  def indexed_from_descriptor(%MatcherDescriptor{} = descriptor) do
    with {:ok, shape} <- shape_from_descriptor(descriptor) do
      {:ok, forall_telescope(binders(shape), shape.result)}
    end
  end

  @doc "Experimentally emits an indexed matcher value term without enabling checked matcher declarations."
  @spec indexed_value_from_descriptor(MatcherDescriptor.t()) :: {:ok, Term.t()} | {:error, term()}
  def indexed_value_from_descriptor(%MatcherDescriptor{indexed?: false, family: family}),
    do: {:error, {:not_indexed_matcher_value, family}}

  def indexed_value_from_descriptor(%MatcherDescriptor{} = descriptor) do
    with {:ok, shape} <- shape_from_descriptor(descriptor) do
      {:ok, lam_telescope(binders(shape), shape.body)}
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
        recursor: descriptor.recursor,
        recursor_descriptor: descriptor.recursor_descriptor
      }

      shape = plan_motive_result(shape)
      shape = plan_indexed_alternatives(shape)
      recursor_arguments = recursor_arguments(shape)
      shape_with_arguments = %{shape | recursor_arguments: recursor_arguments}
      shape = %{shape_with_arguments | body: body_from_shape(shape_with_arguments)}

      with :ok <- validate_shape(shape), do: {:ok, shape}
    end
  end

  @doc "Validates planned matcher declaration shape invariants."
  @spec validate_shape(Shape.t()) :: :ok | {:error, term()}
  def validate_shape(%Shape{} = shape) do
    with :ok <- validate_common_shape(shape),
         :ok <- validate_recursor_arguments(shape),
         :ok <- validate_recursor_metadata(shape) do
      validate_indexed_shape(shape)
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

  defp validate_common_shape(%Shape{} = shape) do
    cond do
      length(shape.alternatives) != length(shape.alternative_binders) ->
        {:error, {:alternative_binder_count_mismatch, shape.family}}

      Enum.map(shape.alternatives, & &1.binder_name) !=
          Enum.map(shape.alternative_binders, &elem(&1, 0)) ->
        {:error, {:alternative_binder_name_mismatch, shape.family}}

      is_nil(shape.result) ->
        {:error, {:missing_shape_result, shape.family}}

      is_nil(shape.body) ->
        {:error, {:missing_shape_body, shape.family}}

      not is_list(shape.recursor_arguments) ->
        {:error, {:invalid_recursor_arguments, shape.recursor}}

      true ->
        :ok
    end
  end

  defp validate_recursor_arguments(%Shape{} = shape) do
    expected = expected_recursor_arity(shape)
    actual = length(shape.recursor_arguments)

    if actual == expected do
      :ok
    else
      {:error, {:recursor_argument_count_mismatch, shape.recursor, expected, actual}}
    end
  end

  defp validate_recursor_metadata(%Shape{recursor_descriptor: nil}), do: :ok

  defp validate_recursor_metadata(%Shape{family: :bool, discriminants: [_, _]}), do: :ok

  defp validate_recursor_metadata(%Shape{} = shape) do
    recursor = shape.recursor_descriptor.recursor

    cond do
      length(shape.alternatives) != recursor.num_minors ->
        {:error,
         {:recursor_minor_count_mismatch, recursor.name, recursor.num_minors,
          length(shape.alternatives)}}

      length(shape.indices) != recursor.num_indices ->
        {:error,
         {:recursor_index_count_mismatch, recursor.name, recursor.num_indices,
          length(shape.indices)}}

      length(shape.index_binders) != recursor.num_indices ->
        {:error,
         {:recursor_index_binder_count_mismatch, recursor.name, recursor.num_indices,
          length(shape.index_binders)}}

      true ->
        :ok
    end
  end

  defp validate_indexed_shape(%Shape{indexed?: false}), do: :ok

  defp validate_indexed_shape(%Shape{indexed?: true} = shape) do
    cond do
      shape.index_binders != shape.indices ->
        {:error, {:index_binder_mismatch, shape.family}}

      shape.motive_binders == [] ->
        {:error, {:missing_motive_binders, shape.family}}

      length(shape.motive_arguments) != length(shape.motive_binders) ->
        {:error, {:motive_argument_count_mismatch, shape.family}}

      is_nil(shape.motive_result) ->
        {:error, {:missing_motive_result, shape.family}}

      true ->
        validate_indexed_alternatives(shape)
    end
  end

  defp validate_indexed_alternatives(%Shape{} = shape) do
    Enum.reduce_while(shape.alternatives, :ok, fn alternative, :ok ->
      cond do
        not Map.has_key?(shape.index_patterns, alternative.constructor) ->
          {:halt, {:error, {:missing_index_patterns, alternative.constructor}}}

        length(alternative.index_patterns) != length(shape.index_binders) ->
          {:halt, {:error, {:index_pattern_count_mismatch, alternative.constructor}}}

        is_nil(alternative.case_result) ->
          {:halt, {:error, {:missing_case_result, alternative.constructor}}}

        length(alternative.motive_arguments) != length(shape.motive_binders) ->
          {:halt,
           {:error, {:alternative_motive_argument_count_mismatch, alternative.constructor}}}

        forall_result(alternative.binder_type) != alternative.case_result ->
          {:halt, {:error, {:case_result_mismatch, alternative.constructor}}}

        true ->
          {:cont, :ok}
      end
    end)
  end

  defp forall_result(%Term.Forall{body: body}), do: forall_result(body)
  defp forall_result(term), do: term

  defp expected_recursor_arity(%Shape{family: :bool, discriminants: [_, _]}), do: 7

  defp expected_recursor_arity(%Shape{recursor_descriptor: %{recursor: recursor}}) do
    recursor.num_params + recursor.num_motives + recursor.num_minors + recursor.num_indices + 1
  end

  defp expected_recursor_arity(%Shape{recursor: :bool_rec}), do: 4
  defp expected_recursor_arity(%Shape{recursor: :nat_rec}), do: 4
  defp expected_recursor_arity(%Shape{recursor: :list_rec}), do: 5
  defp expected_recursor_arity(%Shape{recursor: :vec_ind}), do: 6
  defp expected_recursor_arity(%Shape{}), do: 0

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
    motive_index = Term.bvar(0)
    motive_parameter = Term.bvar(1)
    motive_vec = Term.const(:Vec, [1]) |> Term.app(motive_parameter) |> Term.app(motive_index)
    discriminant_index = Term.bvar(0)
    discriminant_parameter = Term.bvar(2)

    discriminant_vec =
      Term.const(:Vec, [1]) |> Term.app(discriminant_parameter) |> Term.app(discriminant_index)

    {:ok,
     [
       motive_type: Term.forall(:n, index_type, Term.forall(:_, motive_vec, Term.sort(1))),
       motive_binders: [n: index_type, xs: discriminant_vec],
       discriminant_binders: [xs: discriminant_vec],
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
      shape.alternatives
      |> Enum.with_index()
      |> Enum.map(fn {alternative, position} ->
        plan_indexed_alternative(shape, alternative, position)
      end)

    %{
      shape
      | alternatives: alternatives,
        alternative_binders: Enum.map(alternatives, &{&1.binder_name, &1.binder_type})
    }
  end

  defp plan_indexed_alternative(
         %Shape{family: :Vec} = shape,
         %Alternative{constructor: :vec_nil} = alternative,
         position
       ) do
    previous_binders = indexed_binders_before_alternative(shape, position)
    motive = binder_ref_in(previous_binders, shape.motive_name)
    constructor = Term.const(:vec_nil, [1]) |> Term.app(binder_ref_in(previous_binders, :a))
    motive_arguments = [Term.const(:zero), constructor]
    case_result = apply_motive(motive, motive_arguments)

    %{
      alternative
      | motive_arguments: motive_arguments,
        case_result: case_result,
        binder_type: case_result
    }
  end

  defp plan_indexed_alternative(
         %Shape{family: :Vec},
         %Alternative{constructor: :vec_cons} = alternative,
         _position
       ) do
    motive_n_arg2 = Term.bvar(6) |> Term.app(Term.bvar(1)) |> Term.app(Term.bvar(0))
    succ_n = Term.const(:succ) |> Term.app(Term.bvar(2))

    constructor =
      Term.const(:vec_cons, [1])
      |> Term.app(Term.bvar(8))
      |> Term.app(Term.bvar(3))
      |> Term.app(Term.bvar(2))
      |> Term.app(Term.bvar(1))

    motive_arguments = [succ_n, constructor]
    case_result = Term.bvar(7) |> Term.app(succ_n) |> Term.app(constructor)

    binder_type =
      forall_telescope(
        [
          _: Term.bvar(4),
          _: Term.const(:Nat),
          _: Term.const(:Vec, [1]) |> Term.app(Term.bvar(6)) |> Term.app(Term.bvar(0)),
          _: motive_n_arg2
        ],
        case_result
      )

    %{
      alternative
      | motive_arguments: motive_arguments,
        case_result: case_result,
        binder_type: binder_type
    }
  end

  defp plan_indexed_alternative(%Shape{} = shape, %Alternative{} = alternative, position) do
    previous_binders = indexed_binders_before_alternative(shape, position)
    fields = Enum.map(alternative.fields, &{:_, &1.type})
    motive = binder_ref_in(previous_binders ++ fields, shape.motive_name)
    motive_arguments = alternative_motive_arguments(shape, alternative, previous_binders, fields)
    case_result = apply_motive(motive, motive_arguments)

    %{
      alternative
      | motive_arguments: motive_arguments,
        case_result: case_result,
        binder_type: indexed_case_telescope(alternative, case_result)
    }
  end

  defp indexed_binders_before_alternative(%Shape{} = shape, position) do
    shape.parameters ++
      [{shape.motive_name, shape.motive_type}] ++
      shape.index_binders ++
      shape.discriminant_binders ++
      (shape.alternatives
       |> Enum.take(position)
       |> Enum.map(&{&1.binder_name, &1.binder_type}))
  end

  defp alternative_motive_arguments(
         %Shape{family: :Vec},
         %Alternative{constructor: :vec_nil},
         binders,
         fields
       ) do
    [
      Term.const(:zero),
      Term.const(:vec_nil, [1]) |> Term.app(binder_ref_in(binders ++ fields, :a))
    ]
  end

  defp alternative_motive_arguments(
         %Shape{family: :Vec},
         %Alternative{constructor: :vec_cons} = alternative,
         binders,
         fields
       ) do
    alternative.index_patterns ++ [constructor_application(alternative, binders, fields)]
  end

  defp alternative_motive_arguments(_shape, alternative, _binders, _fields) do
    alternative.index_patterns ++ [constructor_application(alternative)]
  end

  defp constructor_application(%Alternative{} = alternative, binders, fields) do
    field_count = length(fields)
    parameter = Term.shift(binder_ref_in(binders, :a), field_count)
    field_arguments = Enum.map(alternative.fields, &Term.bvar(field_count - &1.position - 1))

    [parameter | field_arguments]
    |> Enum.reduce(Term.const(alternative.constructor, [1]), fn argument, term ->
      Term.app(term, argument)
    end)
  end

  defp constructor_application(%Alternative{} = alternative) do
    alternative.fields
    |> Enum.map(&Term.bvar(length(alternative.fields) - &1.position - 1))
    |> Enum.reduce(Term.const(alternative.constructor), fn argument, term ->
      Term.app(term, argument)
    end)
  end

  defp apply_motive(motive, arguments), do: Enum.reduce(arguments, motive, &Term.app(&2, &1))

  defp recursor_arguments(%Shape{family: :Vec} = shape) do
    [
      binder_ref(shape, :a),
      binder_ref(shape, :motive),
      binder_ref(shape, :on_vec_nil),
      binder_ref(shape, :on_vec_cons),
      binder_ref(shape, :n),
      binder_ref(shape, :xs)
    ]
  end

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

  defp body_from_shape(%Shape{family: :Vec} = shape) do
    apply_recursor!(shape.recursor, shape.recursor_arguments)
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

  defp binder_ref(%Shape{} = shape, name), do: binder_ref_in(shape_binders(shape), name)

  defp binder_ref_in(binders, name) do
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
