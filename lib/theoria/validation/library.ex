defmodule Theoria.Validation.Library do
  @moduledoc "Validation checks owned by a Theoria library."

  @enforce_keys [:theorem, :defeq, :inductive]
  defstruct [:theorem, :defeq, :inductive]

  @type t :: %__MODULE__{
          theorem: Theoria.Validation.TheoremModuleCheck.t(),
          defeq: [Theoria.Validation.DefeqCheck.t()],
          inductive: [Theoria.Validation.InductiveCheck.t()]
        }

  @doc "Builds library validation checks."
  @spec new(Theoria.Validation.TheoremModuleCheck.t(), [term()], [term()]) :: t()
  def new(theorem, defeq \\ [], inductive \\ []) do
    %__MODULE__{theorem: theorem, defeq: defeq, inductive: inductive}
  end
end
