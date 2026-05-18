defmodule Theoria.Equation.Matcher.Info do
  @moduledoc "Experimental/internal API for 0.2; subject to change before 0.3. Small Theoria-side mirror of Lean matcher metadata."

  defmodule Alternative do
    @moduledoc "Metadata for one matcher alternative."

    @enforce_keys [:constructor, :num_fields]
    defstruct [:constructor, :num_fields, pattern: nil, num_overlaps: 0, has_unit_thunk?: false]

    @type t :: %__MODULE__{
            constructor: atom() | boolean(),
            num_fields: non_neg_integer(),
            pattern: [atom() | boolean()] | nil,
            num_overlaps: non_neg_integer(),
            has_unit_thunk?: boolean()
          }
  end

  defmodule Discriminant do
    @moduledoc "Metadata for one matcher discriminant."

    alias Theoria.Term

    defstruct [:name, :position, :type, :family]

    @type t :: %__MODULE__{
            name: atom() | nil,
            position: non_neg_integer() | nil,
            type: Term.t() | nil,
            family: atom() | nil
          }
  end

  @enforce_keys [:name, :num_params, :num_discriminants, :alternatives]
  defstruct [
    :name,
    :num_params,
    :num_discriminants,
    :alternatives,
    elim_level_position: nil,
    discriminants: [],
    overlaps: %{}
  ]

  @type t :: %__MODULE__{
          name: atom(),
          num_params: non_neg_integer(),
          num_discriminants: pos_integer(),
          alternatives: [Alternative.t()],
          elim_level_position: non_neg_integer() | nil,
          discriminants: [Discriminant.t()],
          overlaps: %{optional(non_neg_integer()) => [non_neg_integer()]}
        }

  @doc "Builds matcher metadata."
  @spec new(atom(), non_neg_integer(), pos_integer(), [Alternative.t()], keyword()) :: t()
  def new(name, num_params, num_discriminants, alternatives, opts \\ [])
      when is_atom(name) and is_integer(num_params) and is_integer(num_discriminants) and
             is_list(alternatives) do
    %__MODULE__{
      name: name,
      num_params: num_params,
      num_discriminants: num_discriminants,
      alternatives: alternatives,
      elim_level_position: Keyword.get(opts, :elim_level_position),
      discriminants: Keyword.get(opts, :discriminants, default_discriminants(num_discriminants)),
      overlaps: Keyword.get(opts, :overlaps, %{})
    }
  end

  @doc "Builds matcher metadata from supported equation schema metadata."
  @spec for_schema(atom(), Theoria.Equation.Schema.t(), keyword()) :: t()
  def for_schema(definition_name, %Theoria.Equation.Schema{family: family} = schema, opts \\ []) do
    discriminant_count = opts |> Keyword.get(:discriminants, []) |> length() |> max(1)

    new(
      :"#{definition_name}_match_1",
      num_params(family),
      discriminant_count,
      alternatives(family, schema, discriminant_count),
      opts
    )
  end

  @doc "Returns total matcher arity in Lean's broad shape: params + motive + discriminants + alternatives."
  @spec arity(t()) :: non_neg_integer()
  def arity(%__MODULE__{} = info) do
    info.num_params + 1 + info.num_discriminants + length(info.alternatives)
  end

  defp default_discriminants(count), do: Enum.map(1..count//1, fn _index -> %Discriminant{} end)

  defp num_params(:list), do: 1
  defp num_params(_family), do: 0

  defp alternatives(:bool, schema, count) when count > 1 do
    Enum.map(schema.equations, fn equation ->
      %Alternative{
        constructor: equation.suffix,
        pattern: suffix_pattern(equation.suffix),
        num_fields: 0
      }
    end)
  end

  defp alternatives(:bool, _schema, _count) do
    [
      %Alternative{constructor: true, pattern: [true], num_fields: 0},
      %Alternative{constructor: false, pattern: [false], num_fields: 0}
    ]
  end

  defp alternatives(:nat, _schema, _count) do
    [
      %Alternative{constructor: :zero, num_fields: 0},
      %Alternative{constructor: :succ, num_fields: 1}
    ]
  end

  defp alternatives(:list, _schema, _count) do
    [
      %Alternative{constructor: :list_nil, num_fields: 0},
      %Alternative{constructor: :list_cons, num_fields: 2}
    ]
  end

  defp suffix_pattern(:true_true), do: [true, true]
  defp suffix_pattern(:true_false), do: [true, false]
  defp suffix_pattern(:false_true), do: [false, true]
  defp suffix_pattern(:false_false), do: [false, false]
  defp suffix_pattern(suffix), do: [suffix]
end
