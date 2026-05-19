defmodule Theoria.Kernel.ArtifactReplay.Skip do
  @moduledoc """
  Experimental generated-artifact replay skip entry for Theoria 0.5 assurance reports.

  The shape may change before 1.0.
  """

  alias Theoria.Env
  alias Theoria.Equation.Identity

  @enforce_keys [:name, :reason]
  defstruct [:name, :reason, details: []]

  @type t :: %__MODULE__{
          name: Env.name() | Identity.t(),
          reason: atom(),
          details: term()
        }

  @spec new(Env.name() | Identity.t(), atom(), term()) :: t()
  def new(name, reason, details \\ []),
    do: %__MODULE__{name: name, reason: reason, details: details}
end
