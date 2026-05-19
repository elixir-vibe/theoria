defmodule Theoria.Equation.Matcher.Descriptor do
  @moduledoc "Experimental before 1.0; the shape may change. Internal descriptor-driven matcher generation metadata."

  alias Theoria.Env
  alias Theoria.Equation.Matcher.Info, as: MatcherInfo
  alias Theoria.Equation.Recursor.Descriptor, as: RecursorDescriptor
  alias Theoria.Equation.Schema
  alias Theoria.Term

  defmodule Field do
    @moduledoc "Normalized constructor field shape for matcher descriptors."

    alias Theoria.Term

    @enforce_keys [:name, :type, :position]
    defstruct [:name, :type, :position, recursive?: false, recursive_indices: []]

    @type t :: %__MODULE__{
            name: atom(),
            type: Term.t(),
            position: non_neg_integer(),
            recursive?: boolean(),
            recursive_indices: [Term.t()]
          }
  end

  defmodule Alternative do
    @moduledoc "Descriptor for one matcher alternative."

    alias Theoria.Equation.Matcher.Descriptor.Field
    alias Theoria.Term

    @enforce_keys [:name, :pattern, :fields, :result]
    defstruct [
      :name,
      :pattern,
      :fields,
      :result,
      recursive_fields: [],
      recursive_hypotheses: [],
      index_patterns: []
    ]

    @type t :: %__MODULE__{
            name: atom() | boolean(),
            pattern: [atom() | boolean()],
            fields: [Field.t()],
            recursive_fields: [Field.t()],
            recursive_hypotheses: [{atom(), Term.t()}],
            index_patterns: [Term.t()],
            result: Term.t()
          }
  end

  @enforce_keys [:family, :parameters, :discriminants, :alternatives, :result, :recursor]
  defstruct [
    :family,
    :parameters,
    :discriminants,
    :alternatives,
    :result,
    :recursor,
    :recursor_descriptor,
    indexed?: false,
    indices: [],
    recursive?: false
  ]

  @type t :: %__MODULE__{
          family: atom(),
          parameters: [{atom(), Term.t()}],
          indices: [{atom(), Term.t()}],
          indexed?: boolean(),
          recursive?: boolean(),
          discriminants: [MatcherInfo.Discriminant.t()],
          alternatives: [Alternative.t()],
          result: Term.t(),
          recursor: atom(),
          recursor_descriptor: RecursorDescriptor.t() | nil
        }

  @doc "Builds a matcher descriptor from schema and matcher metadata."
  @spec from_schema(Schema.t(), MatcherInfo.t()) ::
          {:ok, t()} | {:error, term()}
  def from_schema(%Schema{} = schema, %MatcherInfo{} = info) do
    build(schema, info, nil)
  end

  @doc "Builds a matcher descriptor from checked recursor metadata when an environment is available."
  @spec from_env(Env.t(), Schema.t(), MatcherInfo.t()) ::
          {:ok, t()} | {:error, term()}
  def from_env(%Env{} = env, %Schema{} = schema, %MatcherInfo{} = info) do
    with {:ok, recursor} <- RecursorDescriptor.from_schema(env, schema) do
      from_recursor(schema, info, recursor)
    end
  end

  @doc "Builds a matcher descriptor from schema, matcher metadata, and recursor shape metadata."
  @spec from_recursor(Schema.t(), MatcherInfo.t(), RecursorDescriptor.t()) ::
          {:ok, t()} | {:error, term()}
  def from_recursor(%Schema{} = schema, %MatcherInfo{} = info, %RecursorDescriptor{} = recursor) do
    build(schema, info, recursor)
  end

  @doc "Returns the normalized field name."
  @spec field_name(Field.t()) :: atom()
  def field_name(%Field{name: name}), do: name

  @doc "Returns the normalized field type."
  @spec field_type(Field.t()) :: Term.t()
  def field_type(%Field{type: type}), do: type

  @doc "Returns whether a normalized field is recursive."
  @spec recursive_field?(Field.t()) :: boolean()
  def recursive_field?(%Field{recursive?: recursive?}), do: recursive?

  @doc "Returns normalized field types for an alternative."
  @spec alternative_field_types(Alternative.t()) :: [Term.t()]
  def alternative_field_types(%Alternative{} = alternative),
    do: Enum.map(alternative.fields, &field_type/1)

  @doc "Validates descriptor consistency against matcher metadata."
  @spec validate(t(), MatcherInfo.t()) :: :ok | {:error, term()}
  def validate(%__MODULE__{} = descriptor, %MatcherInfo{} = info) do
    cond do
      length(descriptor.discriminants) != info.num_discriminants ->
        {:error, {:discriminant_count_mismatch, info.num_discriminants}}

      length(descriptor.alternatives) != length(info.alternatives) ->
        {:error, {:alternative_count_mismatch, length(info.alternatives)}}

      duplicate_alternative?(descriptor.alternatives) ->
        {:error, :duplicate_alternative}

      descriptor.recursor not in [:bool_rec, :nat_rec, :list_rec, :vec_ind] ->
        {:error, {:unsupported_recursor, descriptor.recursor}}

      invalid_indexed_alternative?(descriptor) ->
        {:error, {:index_pattern_count_mismatch, length(descriptor.indices)}}

      invalid_recursive_fields?(descriptor) ->
        {:error, :invalid_recursive_fields}

      true ->
        :ok
    end
  end

  defp duplicate_alternative?(alternatives) do
    names = Enum.map(alternatives, & &1.name)
    length(names) != MapSet.size(MapSet.new(names))
  end

  defp invalid_indexed_alternative?(%__MODULE__{indexed?: false}), do: false

  defp invalid_indexed_alternative?(%__MODULE__{} = descriptor) do
    Enum.any?(descriptor.alternatives, &(length(&1.index_patterns) != length(descriptor.indices)))
  end

  defp invalid_recursive_fields?(%__MODULE__{} = descriptor) do
    Enum.any?(descriptor.alternatives, fn alternative ->
      fields = MapSet.new(Enum.map(alternative.fields, &field_name/1))
      recursive_fields = MapSet.new(Enum.map(alternative.recursive_fields, &field_name/1))
      not MapSet.subset?(recursive_fields, fields)
    end)
  end

  defp build(%Schema{} = schema, %MatcherInfo{} = info, recursor_descriptor) do
    with :ok <- validate_recursor_shape(schema.family, info, recursor_descriptor) do
      descriptor = %__MODULE__{
        family: schema.family,
        parameters: schema.parameter_binders,
        indices: indices(recursor_descriptor),
        indexed?: indexed?(recursor_descriptor),
        recursive?: recursive?(recursor_descriptor),
        discriminants: info.discriminants,
        alternatives: alternatives(schema.family, info, recursor_descriptor),
        result: result(schema.family),
        recursor: recursor_name(schema.family, recursor_descriptor),
        recursor_descriptor: recursor_descriptor
      }

      validate(descriptor, info)
      |> case do
        :ok -> {:ok, descriptor}
        {:error, _reason} = error -> error
      end
    end
  end

  defp alternatives(:bool, %MatcherInfo{} = info, _recursor_descriptor) do
    Enum.map(info.alternatives, fn alternative ->
      %Alternative{
        name: alternative.constructor,
        pattern: alternative.pattern || [alternative.constructor],
        fields: [],
        result: Term.bvar(1)
      }
    end)
  end

  defp alternatives(:nat, %MatcherInfo{} = info, %RecursorDescriptor{} = recursor_descriptor) do
    alternatives_from_recursor(info, recursor_descriptor, fn
      :zero -> Term.bvar(1)
      :succ -> Term.bvar(2)
    end)
  end

  defp alternatives(:nat, %MatcherInfo{} = info, nil) do
    Enum.map(info.alternatives, fn
      %{constructor: :zero} ->
        %Alternative{name: :zero, pattern: [:zero], fields: [], result: Term.bvar(1)}

      %{constructor: :succ} ->
        %Alternative{
          name: :succ,
          pattern: [:succ],
          fields: [field(:pred, Term.const(:Nat), 0)],
          recursive_hypotheses: [{:ih, Term.bvar(3)}],
          result: Term.bvar(2)
        }
    end)
  end

  defp alternatives(:list, %MatcherInfo{} = info, %RecursorDescriptor{} = recursor_descriptor) do
    alternatives_from_recursor(info, recursor_descriptor, fn
      :list_nil -> Term.bvar(1)
      :list_cons -> Term.bvar(2)
    end)
  end

  defp alternatives(:list, %MatcherInfo{} = info, nil) do
    Enum.map(info.alternatives, fn
      %{constructor: :list_nil} ->
        %Alternative{name: :list_nil, pattern: [:list_nil], fields: [], result: Term.bvar(1)}

      %{constructor: :list_cons} ->
        element_type = Term.bvar(0)

        %Alternative{
          name: :list_cons,
          pattern: [:list_cons],
          fields: [field(:head, element_type, 0), field(:tail, list_of(element_type), 1)],
          recursive_hypotheses: [{:ih, Term.bvar(4)}],
          result: Term.bvar(2)
        }
    end)
  end

  defp alternatives(:Vec, %MatcherInfo{} = info, %RecursorDescriptor{} = recursor_descriptor) do
    alternatives_from_recursor(info, recursor_descriptor, fn _constructor -> Term.bvar(0) end)
  end

  defp alternatives_from_recursor(
         %MatcherInfo{} = info,
         %RecursorDescriptor{} = recursor_descriptor,
         result_fun
       ) do
    rules = rules_by_constructor(recursor_descriptor)

    Enum.map(info.alternatives, fn alternative ->
      rule = Map.fetch!(rules, alternative.constructor)

      %Alternative{
        name: alternative.constructor,
        pattern: alternative.pattern || [alternative.constructor],
        fields: normalize_fields(rule.fields),
        recursive_fields: normalize_fields(rule.recursive_fields),
        recursive_hypotheses: recursive_hypotheses(rule),
        index_patterns: rule.index_patterns,
        result: result_fun.(alternative.constructor)
      }
    end)
  end

  defp result(_family), do: Term.bvar(0)

  defp field(name, type, position, opts \\ []) do
    %Field{
      name: name,
      type: type,
      position: position,
      recursive?: Keyword.get(opts, :recursive?, false),
      recursive_indices: Keyword.get(opts, :recursive_indices, [])
    }
  end

  defp normalize_fields(fields), do: Enum.map(fields, &normalize_field/1)

  defp normalize_field(%RecursorDescriptor.Rule.Field{} = field) do
    %Field{
      name: field.name,
      type: field.type,
      position: field.position,
      recursive?: field.recursive?,
      recursive_indices: field.recursive_indices
    }
  end

  defp normalize_field(%Field{} = field), do: field

  defp indices(%RecursorDescriptor{} = descriptor), do: descriptor.indices
  defp indices(nil), do: []

  defp indexed?(%RecursorDescriptor{} = descriptor), do: descriptor.indexed?
  defp indexed?(nil), do: false

  defp recursive?(%RecursorDescriptor{} = descriptor) do
    Enum.any?(descriptor.rules, &(&1.recursive_fields != []))
  end

  defp recursive?(nil), do: false

  defp recursive_hypotheses(%RecursorDescriptor.Rule{} = rule) do
    Enum.map(rule.recursive_fields, &{String.to_atom("#{&1.name}_ih"), Term.bvar(0)})
  end

  defp validate_recursor_shape(_family, _info, nil), do: :ok

  defp validate_recursor_shape(
         family,
         %MatcherInfo{} = info,
         %RecursorDescriptor{} = recursor
       ) do
    rules = rules_by_constructor(recursor)

    with :ok <- validate_info_alternatives(info, rules),
         :ok <- validate_alternative_field_counts(info, rules) do
      validate_family_field_counts(family, rules)
    end
  end

  defp validate_info_alternatives(%MatcherInfo{} = info, rules) do
    constructors = MapSet.new(Map.keys(rules))

    alternatives =
      info.alternatives
      |> Enum.flat_map(&(&1.pattern || [&1.constructor]))
      |> MapSet.new()

    if MapSet.subset?(alternatives, constructors) do
      :ok
    else
      {:error, {:unknown_recursor_alternative, MapSet.difference(alternatives, constructors)}}
    end
  end

  defp validate_alternative_field_counts(%MatcherInfo{} = info, rules) do
    Enum.reduce_while(info.alternatives, :ok, fn alternative, :ok ->
      constructors = alternative.pattern || [alternative.constructor]

      actual_field_count =
        constructors
        |> Enum.map(&Map.fetch(rules, &1))
        |> Enum.reduce_while(0, fn
          {:ok, rule}, count -> {:cont, count + rule.field_count}
          :error, _count -> {:halt, :missing}
        end)

      cond do
        actual_field_count == :missing ->
          {:halt, {:error, {:missing_recursor_rule, alternative.constructor}}}

        actual_field_count == alternative.num_fields ->
          {:cont, :ok}

        true ->
          {:halt,
           {:error,
            {:alternative_field_count_mismatch, alternative.constructor, alternative.num_fields,
             actual_field_count}}}
      end
    end)
  end

  defp validate_family_field_counts(:bool, rules),
    do: validate_field_counts(rules, true: 0, false: 0)

  defp validate_family_field_counts(:nat, rules),
    do: validate_field_counts(rules, zero: 0, succ: 1)

  defp validate_family_field_counts(:list, rules),
    do: validate_field_counts(rules, list_nil: 0, list_cons: 2)

  defp validate_family_field_counts(:Vec, rules),
    do: validate_field_counts(rules, vec_nil: 0, vec_cons: 3)

  defp validate_family_field_counts(family, _rules), do: {:error, {:unsupported_family, family}}

  defp validate_field_counts(rules, expected) do
    Enum.reduce_while(expected, :ok, fn {constructor, field_count}, :ok ->
      case Map.fetch(rules, constructor) do
        {:ok, %{field_count: ^field_count}} ->
          {:cont, :ok}

        {:ok, rule} ->
          {:halt,
           {:error, {:recursor_field_count_mismatch, constructor, field_count, rule.field_count}}}

        :error ->
          {:halt, {:error, {:missing_recursor_rule, constructor}}}
      end
    end)
  end

  defp recursor_name(_family, %RecursorDescriptor{recursor: recursor}),
    do: recursor.name

  defp recursor_name(family, nil), do: RecursorDescriptor.recursor_name(family)

  defp rules_by_constructor(%RecursorDescriptor{} = descriptor) do
    Map.new(descriptor.rules, &{&1.constructor, &1})
  end

  defp list_of(element_type), do: Term.app(Term.const(:List, [1]), element_type)
end
