defmodule Theoria.Equation.MatcherDescriptor do
  @moduledoc "Descriptor-driven matcher generation metadata."

  alias Theoria.Equation.MatcherInfo
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
    descriptor = %__MODULE__{
      family: schema.family,
      parameters: schema.parameter_binders,
      discriminants: info.discriminants,
      alternatives: alternatives(schema.family, info),
      result: result(schema.family),
      recursor: recursor(schema.family)
    }

    with :ok <- validate(descriptor, info) do
      {:ok, descriptor}
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

  defp alternatives(:bool, %MatcherInfo{} = info) do
    Enum.map(info.alternatives, fn alternative ->
      %Alternative{
        name: alternative.constructor,
        pattern: alternative.pattern || [alternative.constructor],
        fields: [],
        result: Term.bvar(1)
      }
    end)
  end

  defp alternatives(:nat, %MatcherInfo{} = info) do
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

  defp alternatives(:list, %MatcherInfo{} = info) do
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

  defp recursor(:bool), do: :bool_rec
  defp recursor(:nat), do: :nat_rec
  defp recursor(:list), do: :list_rec

  defp list_of(element_type), do: Term.app(Term.const(:List, [1]), element_type)
end
