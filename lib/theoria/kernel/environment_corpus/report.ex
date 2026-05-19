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

  @spec replay_checks(t()) :: non_neg_integer()
  def replay_checks(%__MODULE__{replay_checks: replay_checks}), do: replay_checks

  @spec normalize_checks(t()) :: non_neg_integer()
  def normalize_checks(%__MODULE__{normalize_checks: normalize_checks}), do: normalize_checks

  @spec case_names(t()) :: [atom()]
  def case_names(%__MODULE__{cases: cases}), do: Enum.map(cases, & &1.name)

  @spec case(t(), atom()) :: Case.t() | nil
  def case(%__MODULE__{cases: cases}, name), do: Enum.find(cases, &(&1.name == name))

  @spec case_count(t(), atom()) :: non_neg_integer()
  def case_count(%__MODULE__{} = report, name) do
    if __MODULE__.case(report, name), do: 1, else: 0
  end
end
