defmodule Theoria.Kernel.TheoremModuleReport do
  @moduledoc """
  Experimental theorem-module assurance summary for Theoria 0.5 reports.

  The shape may change before 1.0.
  """

  @enforce_keys [:module, :checks, :replay_checks, :replay_skipped, :failures]
  defstruct [:module, :checks, :replay_checks, :replay_skipped, :failures]

  @type t :: %__MODULE__{
          module: module(),
          checks: non_neg_integer(),
          replay_checks: non_neg_integer(),
          replay_skipped: non_neg_integer(),
          failures: [term()]
        }

  @spec module(t()) :: module()
  def module(%__MODULE__{module: module}), do: module

  @spec checks(t()) :: non_neg_integer()
  def checks(%__MODULE__{checks: checks}), do: checks

  @spec replay_checks(t()) :: non_neg_integer()
  def replay_checks(%__MODULE__{replay_checks: replay_checks}), do: replay_checks

  @spec replay_skipped(t()) :: non_neg_integer()
  def replay_skipped(%__MODULE__{replay_skipped: replay_skipped}), do: replay_skipped

  @spec failures(t()) :: [term()]
  def failures(%__MODULE__{failures: failures}), do: failures

  @spec ok?(t()) :: boolean()
  def ok?(%__MODULE__{failures: failures}), do: failures == []

  @spec failure_count(t()) :: non_neg_integer()
  def failure_count(%__MODULE__{failures: failures}), do: length(failures)

  @spec total_checks(t()) :: non_neg_integer()
  def total_checks(%__MODULE__{} = report), do: report.checks + report.replay_checks
end
