defmodule Theoria.Kernel.GeneratedTerm.Failure do
  @moduledoc """
  Diagnostic payload for a generated-term differential failure.

  Experimental in the 0.6 line; the shape may change before 1.0.
  """

  @enforce_keys [:phase, :name, :term, :type, :production, :reference]
  defstruct [:phase, :name, :term, :type, :production, :reference]

  @type t :: %__MODULE__{
          phase: atom(),
          name: term(),
          term: String.t(),
          type: String.t(),
          production: String.t(),
          reference: String.t()
        }

  @spec new(atom(), Theoria.Kernel.GeneratedTerm.t(), term(), term()) :: t()
  def new(phase, generated, production, reference) do
    %__MODULE__{
      phase: phase,
      name: generated.name,
      term: inspect(generated.term),
      type: inspect(generated.type),
      production: inspect(production),
      reference: inspect(reference)
    }
  end
end
