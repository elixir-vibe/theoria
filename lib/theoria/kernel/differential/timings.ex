defmodule Theoria.Kernel.Differential.Timings do
  @moduledoc """
  Experimental assurance-report timing metadata for Theoria 0.5.

  The shape may change before 1.0.
  """

  @enforce_keys [
    :infer_ms,
    :check_ms,
    :normalize_ms,
    :defeq_ms,
    :rejection_ms,
    :generated_term_ms,
    :theorem_ms,
    :generated_artifact_ms,
    :indexed_artifact_ms,
    :replay_ms,
    :artifact_replay_ms,
    :total_ms
  ]
  defstruct [
    :infer_ms,
    :check_ms,
    :normalize_ms,
    :defeq_ms,
    :rejection_ms,
    :generated_term_ms,
    :theorem_ms,
    :generated_artifact_ms,
    :indexed_artifact_ms,
    :replay_ms,
    :artifact_replay_ms,
    :total_ms
  ]

  @type t :: %__MODULE__{
          infer_ms: non_neg_integer(),
          check_ms: non_neg_integer(),
          normalize_ms: non_neg_integer(),
          defeq_ms: non_neg_integer(),
          rejection_ms: non_neg_integer(),
          generated_term_ms: non_neg_integer(),
          theorem_ms: non_neg_integer(),
          generated_artifact_ms: non_neg_integer(),
          indexed_artifact_ms: non_neg_integer(),
          replay_ms: non_neg_integer(),
          artifact_replay_ms: non_neg_integer(),
          total_ms: non_neg_integer()
        }

  @spec elapsed_ms(integer(), integer()) :: non_neg_integer()
  def elapsed_ms(start, stop), do: System.convert_time_unit(stop - start, :native, :millisecond)
end
