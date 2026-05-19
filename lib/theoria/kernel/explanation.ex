defmodule Theoria.Kernel.Explanation do
  @moduledoc "Trust-boundary explanation entry for kernel assurance reports."

  @enforce_keys [:name, :description, :trusted?, :boundary]
  defstruct [:name, :description, :trusted?, :boundary]

  @type t :: %__MODULE__{
          name: atom(),
          description: String.t(),
          trusted?: boolean(),
          boundary: atom()
        }
end
