defmodule Theoria.Env.Inductive do
  @moduledoc "Lean-style metadata for an admitted inductive type former."

  alias Theoria.Term

  @enforce_keys [:name, :type, :universe_params, :num_params, :num_indices, :constructors]
  defstruct [
    :name,
    :type,
    universe_params: [],
    num_params: 0,
    num_indices: 0,
    constructors: [],
    inductives: [],
    num_nested: 0,
    recursive?: false,
    reflexive?: false
  ]

  @type t :: %__MODULE__{
          name: atom(),
          type: Term.t(),
          universe_params: [atom()],
          num_params: non_neg_integer(),
          num_indices: non_neg_integer(),
          constructors: [atom()],
          inductives: [atom()],
          num_nested: non_neg_integer(),
          recursive?: boolean(),
          reflexive?: boolean()
        }
end
