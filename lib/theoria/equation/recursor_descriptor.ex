defmodule Theoria.Equation.RecursorDescriptor do
  @moduledoc "Experimental/internal API for 0.2; subject to change before 0.3. Internal recursor-derived shape metadata for matcher descriptors."

  alias Theoria.Env
  alias Theoria.Env.Recursor
  alias Theoria.Env.RecursorRule
  alias Theoria.Equation.Schema
  alias Theoria.Term

  defmodule Rule do
    @moduledoc "Recursor rule shape used by matcher descriptor generation."

    alias Theoria.Env.Constructor, as: EnvConstructor
    alias Theoria.Env.RecursorRule
    alias Theoria.Term

    @enforce_keys [:constructor, :field_count, :rhs]
    defstruct [
      :constructor,
      :constructor_metadata,
      :field_count,
      :rhs,
      index_patterns: []
    ]

    @type t :: %__MODULE__{
            constructor: atom(),
            constructor_metadata: EnvConstructor.t() | nil,
            field_count: non_neg_integer(),
            rhs: Term.t(),
            index_patterns: [Term.t()]
          }

    @spec from_recursor_rule(RecursorRule.t(), EnvConstructor.t() | nil) :: t()
    def from_recursor_rule(%RecursorRule{} = rule, constructor_metadata) do
      %__MODULE__{
        constructor: rule.constructor,
        constructor_metadata: constructor_metadata,
        field_count: rule.field_count,
        rhs: rule.rhs,
        index_patterns: rule.index_patterns
      }
    end
  end

  @enforce_keys [:family, :recursor, :rules]
  defstruct [
    :family,
    :recursor,
    :rules,
    parameters: [],
    indices: [],
    indexed?: false
  ]

  @type t :: %__MODULE__{
          family: atom(),
          recursor: Recursor.t(),
          parameters: [{atom(), Term.t()}],
          indices: [{atom(), Term.t()}],
          indexed?: boolean(),
          rules: [Rule.t()]
        }

  @doc "Builds recursor-derived matcher shape metadata for a schema."
  @spec from_schema(Env.t(), Schema.t()) :: {:ok, t()} | {:error, term()}
  def from_schema(%Env{} = env, %Schema{} = schema) do
    name = recursor_name(schema.family)

    with {:ok, recursor} <- fetch_recursor(env, name),
         :ok <- validate_recursor(schema, recursor),
         {:ok, rules} <- rules(env, recursor) do
      {:ok,
       %__MODULE__{
         family: schema.family,
         recursor: recursor,
         parameters: schema.parameter_binders,
         indices: index_binders(schema, recursor),
         indexed?: recursor.num_indices > 0,
         rules: rules
       }}
    end
  end

  @doc "Returns the recursor name used by the current equation fragment for a family."
  @spec recursor_name(atom()) :: atom()
  def recursor_name(:bool), do: :bool_rec
  def recursor_name(:nat), do: :nat_rec
  def recursor_name(:list), do: :list_rec
  def recursor_name(:Vec), do: :vec_ind
  def recursor_name(family), do: String.to_atom("#{Macro.underscore(to_string(family))}_rec")

  defp fetch_recursor(env, name) do
    case Env.fetch_recursor(env, name) do
      {:ok, recursor} -> {:ok, recursor}
      :error -> {:error, {:missing_recursor, name}}
    end
  end

  defp validate_recursor(%Schema{} = schema, %Recursor{} = recursor) do
    cond do
      recursor.inductives != [inductive_name(schema.family)] ->
        {:error, {:recursor_family_mismatch, recursor.name, recursor.inductives, schema.family}}

      recursor.num_minors != length(recursor.rules) ->
        {:error, {:recursor_rule_count_mismatch, recursor.name}}

      indexed_rule_mismatch?(recursor) ->
        {:error, {:recursor_index_pattern_mismatch, recursor.name}}

      true ->
        :ok
    end
  end

  defp indexed_rule_mismatch?(%Recursor{num_indices: 0}), do: false

  defp indexed_rule_mismatch?(%Recursor{} = recursor) do
    Enum.any?(recursor.rules, &(length(&1.index_patterns) != recursor.num_indices))
  end

  defp rules(env, %Recursor{} = recursor) do
    Enum.reduce_while(recursor.rules, {:ok, []}, fn %RecursorRule{} = rule, {:ok, rules} ->
      constructor = constructor_metadata(env, rule.constructor)

      case validate_rule(rule, constructor) do
        :ok -> {:cont, {:ok, [Rule.from_recursor_rule(rule, constructor) | rules]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, rules} -> {:ok, Enum.reverse(rules)}
      {:error, _reason} = error -> error
    end
  end

  defp constructor_metadata(env, name) do
    case Env.fetch_constructor(env, name) do
      {:ok, constructor} -> constructor
      :error -> nil
    end
  end

  defp validate_rule(%RecursorRule{} = rule, nil),
    do: {:error, {:missing_constructor, rule.constructor}}

  defp validate_rule(%RecursorRule{} = rule, constructor) do
    if constructor.num_fields == rule.field_count do
      :ok
    else
      {:error,
       {:constructor_field_count_mismatch, rule.constructor, constructor.num_fields,
        rule.field_count}}
    end
  end

  defp index_binders(%Schema{argument_binders: binders}, %Recursor{num_indices: count})
       when count > 0 do
    Enum.take(binders, count)
  end

  defp index_binders(_schema, _recursor), do: []

  defp inductive_name(:bool), do: :Bool
  defp inductive_name(:nat), do: :Nat
  defp inductive_name(:list), do: :List
  defp inductive_name(family), do: family
end
