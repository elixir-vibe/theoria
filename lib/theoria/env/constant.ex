defmodule Theoria.Env.Constant do
  @moduledoc "A checked constant or definition in a kernel environment."

  alias Theoria.Term

  @enforce_keys [:type]
  defstruct [
    :type,
    :value,
    kind: :constant,
    reducible?: false,
    universe_params: [],
    reduction: nil
  ]

  @type kind :: :constant | :axiom | :definition | :theorem
  @type t :: %__MODULE__{
          type: Term.t(),
          value: Term.t() | nil,
          kind: kind(),
          reducible?: boolean(),
          universe_params: [atom()],
          reduction: Theoria.Env.Reduction.t() | nil
        }
end
