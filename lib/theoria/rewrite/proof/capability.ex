defmodule Theoria.Rewrite.Proof.Capability do
  @moduledoc "Proof lifting capability for a rewrite path."

  @enforce_keys [:supported?, :reason, :description]
  defstruct [:supported?, :reason, :description]

  @type t :: %__MODULE__{
          supported?: boolean(),
          reason: atom(),
          description: String.t()
        }
end
