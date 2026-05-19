defmodule Theoria.Rewrite.Proof.Capability.Entry do
  @moduledoc "One proof capability matrix entry."

  alias Theoria.Rewrite.Proof.Capability

  @enforce_keys [:path, :capability]
  defstruct [:path, :capability]

  @type t :: %__MODULE__{path: [atom()], capability: Capability.t()}
end
