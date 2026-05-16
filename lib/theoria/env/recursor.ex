defmodule Theoria.Env.Recursor do
  @moduledoc "Lean-style metadata for an admitted inductive recursor."

  alias Theoria.Env.RecursorRule
  alias Theoria.Term

  @enforce_keys [
    :name,
    :type,
    :universe_params,
    :inductives,
    :num_params,
    :num_indices,
    :num_motives,
    :num_minors,
    :rules
  ]
  defstruct [
    :name,
    :type,
    universe_params: [],
    inductives: [],
    num_params: 0,
    num_indices: 0,
    num_motives: 0,
    num_minors: 0,
    rules: [],
    k?: false
  ]

  @type t :: %__MODULE__{
          name: atom(),
          type: Term.t(),
          universe_params: [atom()],
          inductives: [atom()],
          num_params: non_neg_integer(),
          num_indices: non_neg_integer(),
          num_motives: non_neg_integer(),
          num_minors: non_neg_integer(),
          rules: [RecursorRule.t()],
          k?: boolean()
        }

  @spec major_index(t()) :: non_neg_integer()
  def major_index(%__MODULE__{} = recursor) do
    recursor.num_params + recursor.num_motives + recursor.num_minors + recursor.num_indices
  end
end
