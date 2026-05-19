defmodule Theoria.Equation.Recursor.Descriptor do
  @moduledoc "Experimental before 1.0; the shape may change. Internal recursor-derived shape metadata for matcher descriptors."

  alias Theoria.Env
  alias Theoria.Env.Recursor
  alias Theoria.Env.RecursorRule
  alias Theoria.Equation.Schema
  alias Theoria.Term
  alias Theoria.Term.Application

  defmodule Rule do
    @moduledoc "Recursor rule shape used by matcher descriptor generation."

    alias Theoria.Env.Constructor, as: EnvConstructor
    alias Theoria.Env.RecursorRule
    alias Theoria.Term

    defmodule Field do
      @moduledoc "Constructor field shape in a recursor rule."

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

    @enforce_keys [:constructor, :field_count, :rhs]
    defstruct [
      :constructor,
      :constructor_metadata,
      :field_count,
      :rhs,
      fields: [],
      recursive_fields: [],
      index_patterns: []
    ]

    @type t :: %__MODULE__{
            constructor: atom(),
            constructor_metadata: EnvConstructor.t() | nil,
            field_count: non_neg_integer(),
            rhs: Term.t(),
            fields: [Field.t()],
            recursive_fields: [Field.t()],
            index_patterns: [Term.t()]
          }

    @spec from_recursor_rule(RecursorRule.t(), EnvConstructor.t() | nil, [Field.t()]) :: t()
    def from_recursor_rule(%RecursorRule{} = rule, constructor_metadata, fields) do
      %__MODULE__{
        constructor: rule.constructor,
        constructor_metadata: constructor_metadata,
        field_count: rule.field_count,
        rhs: rule.rhs,
        fields: fields,
        recursive_fields: Enum.filter(fields, & &1.recursive?),
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

      with :ok <- validate_rule(rule, constructor),
           {:ok, fields} <- fields_for_rule(rule, constructor, recursor) do
        {:cont, {:ok, [Rule.from_recursor_rule(rule, constructor, fields) | rules]}}
      else
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

  defp fields_for_rule(%RecursorRule{}, nil, %Recursor{}), do: {:ok, []}

  defp fields_for_rule(%RecursorRule{}, constructor, %Recursor{} = recursor) do
    constructor.type
    |> field_types(constructor.num_params, constructor.num_fields)
    |> case do
      {:ok, field_types} ->
        fields =
          field_types
          |> Enum.with_index()
          |> Enum.map(fn {type, position} ->
            recursive_indices = recursive_field_indices(type, recursor)

            %Rule.Field{
              name: field_name(type, position),
              type: type,
              position: position,
              recursive?: recursive_indices != nil,
              recursive_indices: recursive_indices || []
            }
          end)

        {:ok, fields}

      {:error, _reason} = error ->
        error
    end
  end

  defp field_types(type, num_params, field_count) do
    type
    |> forall_domains()
    |> Enum.drop(num_params)
    |> case do
      domains when length(domains) >= field_count -> {:ok, Enum.take(domains, field_count)}
      domains -> {:error, {:constructor_field_telescope_too_short, length(domains), field_count}}
    end
  end

  defp forall_domains(%Term.Forall{domain: domain, body: body}),
    do: [domain | forall_domains(body)]

  defp forall_domains(_term), do: []

  defp recursive_field_indices(type, %Recursor{inductives: [inductive], num_params: num_params}) do
    {head, args} = Application.collect(type)

    case head do
      %Term.Const{name: ^inductive} -> Enum.drop(args, num_params)
      _other -> nil
    end
  end

  defp recursive_field_indices(_type, _recursor), do: nil

  defp field_name(%Term.Forall{name: name}, _position), do: name
  defp field_name(_type, position), do: String.to_atom("field#{position}")

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
