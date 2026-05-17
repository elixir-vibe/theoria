defmodule Theoria.Equation.MatcherInfo do
  @moduledoc "Small Theoria-side mirror of Lean matcher metadata."

  defmodule Alternative do
    @moduledoc "Metadata for one matcher alternative."

    @enforce_keys [:constructor, :num_fields]
    defstruct [:constructor, :num_fields, num_overlaps: 0, has_unit_thunk?: false]

    @type t :: %__MODULE__{
            constructor: atom(),
            num_fields: non_neg_integer(),
            num_overlaps: non_neg_integer(),
            has_unit_thunk?: boolean()
          }
  end

  defmodule Discriminant do
    @moduledoc "Metadata for one matcher discriminant."

    defstruct [:name]

    @type t :: %__MODULE__{name: atom() | nil}
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
  @spec for_schema(atom(), Theoria.Equation.Schema.t()) :: t()
  def for_schema(definition_name, %Theoria.Equation.Schema{family: family}) do
    new(:"#{definition_name}.match_1", num_params(family), 1, alternatives(family))
  end

  @doc "Returns total matcher arity in Lean's broad shape: params + motive + discriminants + alternatives."
  @spec arity(t()) :: non_neg_integer()
  def arity(%__MODULE__{} = info) do
    info.num_params + 1 + info.num_discriminants + length(info.alternatives)
  end

  defp default_discriminants(count), do: Enum.map(1..count//1, fn _index -> %Discriminant{} end)

  defp num_params(:list), do: 1
  defp num_params(_family), do: 0

  defp alternatives(:bool) do
    [
      %Alternative{constructor: true, num_fields: 0},
      %Alternative{constructor: false, num_fields: 0}
    ]
  end

  defp alternatives(:nat) do
    [
      %Alternative{constructor: :zero, num_fields: 0},
      %Alternative{constructor: :succ, num_fields: 1}
    ]
  end

  defp alternatives(:list) do
    [
      %Alternative{constructor: :list_nil, num_fields: 0},
      %Alternative{constructor: :list_cons, num_fields: 2}
    ]
  end
end
