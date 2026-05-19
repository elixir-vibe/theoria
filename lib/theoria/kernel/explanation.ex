defmodule Theoria.Kernel.Explanation do
  @moduledoc """
  Experimental trust-boundary explanation data for Theoria 0.5 reports.

  The shape may change before 1.0.
  """

  @enforce_keys [:name, :description, :trusted?, :boundary]
  defstruct [:name, :description, :trusted?, :boundary]

  @type t :: %__MODULE__{
          name: atom(),
          description: String.t(),
          trusted?: boolean(),
          boundary: atom()
        }

  @spec default() :: [t()]
  def default do
    [
      %__MODULE__{
        name: :reference_replay,
        description: "replays declarations through the independent reference checker",
        trusted?: false,
        boundary: :assurance
      },
      %__MODULE__{
        name: :theorem_replay,
        description: "installs theorem modules and replays the extended environments",
        trusted?: false,
        boundary: :assurance
      },
      %__MODULE__{
        name: :artifact_replay,
        description: "installs generated artifacts in suitable environments and replays them",
        trusted?: false,
        boundary: :assurance
      },
      %__MODULE__{
        name: :skipped,
        description: "a skipped item was not replayed as an installed declaration",
        trusted?: false,
        boundary: :coverage_gap
      },
      %__MODULE__{
        name: :boundary,
        description: "these checks are assurance, not a formal proof of kernel correctness",
        trusted?: false,
        boundary: :trusted_boundary
      }
    ]
  end
end
