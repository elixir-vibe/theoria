defmodule Theoria.Kernel.EnvironmentCorpus.Report do
  @moduledoc "Structured report for deterministic environment corpus assurance."

  defmodule Case do
    @moduledoc "Per-case environment corpus assurance summary."

    @enforce_keys [:name, :replay_checks, :normalize_checks, :failures]
    defstruct [:name, :replay_checks, :normalize_checks, :failures]

    @type t :: %__MODULE__{
            name: atom(),
            replay_checks: non_neg_integer(),
            normalize_checks: non_neg_integer(),
            failures: [term()]
          }
  end

  @enforce_keys [:total, :replay_checks, :normalize_checks, :cases, :failures]
  defstruct [:total, :replay_checks, :normalize_checks, :cases, :failures]

  @type t :: %__MODULE__{
          total: non_neg_integer(),
          replay_checks: non_neg_integer(),
          normalize_checks: non_neg_integer(),
          cases: [Case.t()],
          failures: [term()]
        }

  @spec new([Case.t()]) :: t()
  def new(cases) when is_list(cases) do
    %__MODULE__{
      total: length(cases),
      replay_checks: Enum.reduce(cases, 0, &(&2 + &1.replay_checks)),
      normalize_checks: Enum.reduce(cases, 0, &(&2 + &1.normalize_checks)),
      cases: cases,
      failures: Enum.flat_map(cases, & &1.failures)
    }
  end

  @spec total(t()) :: non_neg_integer()
  def total(%__MODULE__{total: total}), do: total

  @spec case_count(t(), atom()) :: non_neg_integer()
  def case_count(%__MODULE__{cases: cases}, name) do
    if Enum.any?(cases, &(&1.name == name)), do: 1, else: 0
  end
end
