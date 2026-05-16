defmodule Theoria.Env.Constructor do
  @moduledoc "Lean-style metadata for an admitted inductive constructor."

  alias Theoria.Term

  @enforce_keys [
    :name,
    :type,
    :universe_params,
    :inductive,
    :constructor_index,
    :num_params,
    :num_fields
  ]
  defstruct [
    :name,
    :type,
    :inductive,
    universe_params: [],
    constructor_index: 0,
    num_params: 0,
    num_fields: 0
  ]

  @type t :: %__MODULE__{
          name: atom(),
          type: Term.t(),
          universe_params: [atom()],
          inductive: atom(),
          constructor_index: non_neg_integer(),
          num_params: non_neg_integer(),
          num_fields: non_neg_integer()
        }
end
