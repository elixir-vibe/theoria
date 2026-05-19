defmodule Theoria.Rewrite.Proof.Capability.Entry do
  @moduledoc """
  Experimental proof capability matrix entry for Theoria 0.5.

  The shape may change before 1.0.
  """

  alias Theoria.Rewrite.Proof.Capability

  @enforce_keys [:path, :capability]
  defstruct [:path, :capability]

  @type t :: %__MODULE__{path: [atom()], capability: Capability.t()}
end
