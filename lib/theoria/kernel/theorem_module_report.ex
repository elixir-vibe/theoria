defmodule Theoria.Kernel.TheoremModuleReport do
  @moduledoc "Assurance summary for one theorem module."

  @enforce_keys [:module, :checks, :replay_checks, :replay_skipped, :failures]
  defstruct [:module, :checks, :replay_checks, :replay_skipped, :failures]

  @type t :: %__MODULE__{
          module: module(),
          checks: non_neg_integer(),
          replay_checks: non_neg_integer(),
          replay_skipped: non_neg_integer(),
          failures: [term()]
        }

  @spec ok?(t()) :: boolean()
  def ok?(%__MODULE__{failures: failures}), do: failures == []

  @spec failure_count(t()) :: non_neg_integer()
  def failure_count(%__MODULE__{failures: failures}), do: length(failures)

  @spec total_checks(t()) :: non_neg_integer()
  def total_checks(%__MODULE__{} = report), do: report.checks + report.replay_checks
end
