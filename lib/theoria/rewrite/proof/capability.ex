defmodule Theoria.Rewrite.Proof.Capability do
  @moduledoc """
  Experimental proof-lifting capability descriptor for Theoria 0.5.

  The shape may change before 1.0.
  """

  @enforce_keys [:supported?, :reason, :description]
  defstruct [:supported?, :reason, :description, inner: nil]

  @type t :: %__MODULE__{
          supported?: boolean(),
          reason: atom(),
          description: String.t(),
          inner: t() | nil
        }
end
