defmodule Theoria.Env.Constant do
  @moduledoc "A checked constant or definition in a kernel environment."

  alias Theoria.Term

  @enforce_keys [:type]
  defstruct [:type, :value, kind: :constant, reducible?: false]

  @type kind :: :constant | :axiom | :definition | :theorem
  @type t :: %__MODULE__{
          type: Term.t(),
          value: Term.t() | nil,
          kind: kind(),
          reducible?: boolean()
        }
end
