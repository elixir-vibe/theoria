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

  @enforce_keys [:name, :num_params, :num_discriminants, :alternatives]
  defstruct [:name, :num_params, :num_discriminants, :alternatives, elim_level_position: nil]

  @type t :: %__MODULE__{
          name: atom(),
          num_params: non_neg_integer(),
          num_discriminants: pos_integer(),
          alternatives: [Alternative.t()],
          elim_level_position: non_neg_integer() | nil
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
      elim_level_position: Keyword.get(opts, :elim_level_position)
    }
  end

  @doc "Returns total matcher arity in Lean's broad shape: params + motive + discriminants + alternatives."
  @spec arity(t()) :: non_neg_integer()
  def arity(%__MODULE__{} = info) do
    info.num_params + 1 + info.num_discriminants + length(info.alternatives)
  end
end
