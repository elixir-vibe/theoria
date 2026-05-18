defmodule Theoria.Equation.MatcherDescriptor do
  @moduledoc "Experimental/internal API for 0.2; subject to change before 0.3. Internal descriptor-driven matcher generation metadata."

  alias Theoria.Env
  alias Theoria.Equation.MatcherInfo
  alias Theoria.Equation.RecursorDescriptor
  alias Theoria.Equation.Schema
  alias Theoria.Term

  defmodule Alternative do
    @moduledoc "Descriptor for one matcher alternative."

    alias Theoria.Term

    @enforce_keys [:name, :pattern, :fields, :result]
    defstruct [:name, :pattern, :fields, :result, recursive_hypotheses: []]

    @type t :: %__MODULE__{
            name: atom() | boolean(),
            pattern: [atom() | boolean()],
            fields: [{atom(), Term.t()}],
            recursive_hypotheses: [{atom(), Term.t()}],
            result: Term.t()
          }
  end

  @enforce_keys [:family, :parameters, :discriminants, :alternatives, :result, :recursor]
  defstruct [:family, :parameters, :discriminants, :alternatives, :result, :recursor]

  @type t :: %__MODULE__{
          family: atom(),
          parameters: [{atom(), Term.t()}],
          discriminants: [MatcherInfo.Discriminant.t()],
          alternatives: [Alternative.t()],
          result: Term.t(),
          recursor: atom()
        }

  @doc "Builds a matcher descriptor from schema and matcher metadata."
  @spec from_schema(Schema.t(), MatcherInfo.t()) :: {:ok, t()} | {:error, term()}
  def from_schema(%Schema{} = schema, %MatcherInfo{} = info) do
    build(schema, info, nil)
  end

  @doc "Builds a matcher descriptor from checked recursor metadata when an environment is available."
  @spec from_env(Env.t(), Schema.t(), MatcherInfo.t()) :: {:ok, t()} | {:error, term()}
  def from_env(%Env{} = env, %Schema{} = schema, %MatcherInfo{} = info) do
    with {:ok, recursor} <- RecursorDescriptor.from_schema(env, schema) do
      build(schema, info, recursor)
    end
  end

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

      descriptor.recursor not in [:bool_rec, :nat_rec, :list_rec] ->
        {:error, {:unsupported_recursor, descriptor.recursor}}

      true ->
        :ok
    end
  end

  defp duplicate_alternative?(alternatives) do
    names = Enum.map(alternatives, & &1.name)
    length(names) != MapSet.size(MapSet.new(names))
  end

  defp build(%Schema{} = schema, %MatcherInfo{} = info, recursor_descriptor) do
    with :ok <- validate_recursor_shape(schema.family, info, recursor_descriptor) do
      descriptor = %__MODULE__{
        family: schema.family,
        parameters: schema.parameter_binders,
        discriminants: info.discriminants,
        alternatives: alternatives(schema.family, info, recursor_descriptor),
        result: result(schema.family),
        recursor: recursor_name(schema.family, recursor_descriptor)
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

  defp alternatives(:nat, %MatcherInfo{} = info, _recursor_descriptor) do
    Enum.map(info.alternatives, fn
      %{constructor: :zero} ->
        %Alternative{name: :zero, pattern: [:zero], fields: [], result: Term.bvar(1)}

      %{constructor: :succ} ->
        %Alternative{
          name: :succ,
          pattern: [:succ],
          fields: [{:pred, Term.const(:Nat)}],
          recursive_hypotheses: [{:ih, Term.bvar(3)}],
          result: Term.bvar(2)
        }
    end)
  end

  defp alternatives(:list, %MatcherInfo{} = info, _recursor_descriptor) do
    Enum.map(info.alternatives, fn
      %{constructor: :list_nil} ->
        %Alternative{name: :list_nil, pattern: [:list_nil], fields: [], result: Term.bvar(1)}

      %{constructor: :list_cons} ->
        element_type = Term.bvar(0)

        %Alternative{
          name: :list_cons,
          pattern: [:list_cons],
          fields: [{:head, element_type}, {:tail, list_of(element_type)}],
          recursive_hypotheses: [{:ih, Term.bvar(4)}],
          result: Term.bvar(2)
        }
    end)
  end

  defp result(_family), do: Term.bvar(0)

  defp validate_recursor_shape(_family, _info, nil), do: :ok

  defp validate_recursor_shape(family, %MatcherInfo{} = info, %RecursorDescriptor{} = recursor) do
    rules = rules_by_constructor(recursor)

    with :ok <- validate_info_alternatives(info, rules) do
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

  defp validate_family_field_counts(:bool, rules),
    do: validate_field_counts(rules, true: 0, false: 0)

  defp validate_family_field_counts(:nat, rules),
    do: validate_field_counts(rules, zero: 0, succ: 1)

  defp validate_family_field_counts(:list, rules),
    do: validate_field_counts(rules, list_nil: 0, list_cons: 2)

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

  defp recursor_name(_family, %RecursorDescriptor{recursor: recursor}), do: recursor.name
  defp recursor_name(family, nil), do: RecursorDescriptor.recursor_name(family)

  defp rules_by_constructor(%RecursorDescriptor{} = descriptor) do
    Map.new(descriptor.rules, &{&1.constructor, &1})
  end

  defp list_of(element_type), do: Term.app(Term.const(:List, [1]), element_type)
end
