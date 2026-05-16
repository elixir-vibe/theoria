defmodule Theoria.Env.Constant do
  @moduledoc "A checked constant or definition in a kernel environment."

  alias Theoria.Term

  @enforce_keys [:type]
  defstruct [:type, :value]

  @type t :: %__MODULE__{type: Term.t(), value: Term.t() | nil}
end
