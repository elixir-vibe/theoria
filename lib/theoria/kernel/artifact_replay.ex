defmodule Theoria.Kernel.ArtifactReplay do
  @moduledoc """
  Experimental generated-artifact replay summary.

  The shape may change before 1.0.
  """

  alias Theoria.Kernel.ArtifactReplay.Skip

  @enforce_keys [:generated_checked, :indexed_checked, :skipped, :failures]
  defstruct [:generated_checked, :indexed_checked, :skipped, :failures]

  @type skip :: Skip.t()
  @type failure :: term()
  @type t :: %__MODULE__{
          generated_checked: non_neg_integer(),
          indexed_checked: non_neg_integer(),
          skipped: [skip()],
          failures: [failure()]
        }

  @spec checked(t()) :: non_neg_integer()
  def checked(%__MODULE__{} = replay), do: replay.generated_checked + replay.indexed_checked

  @spec generated_checked(t()) :: non_neg_integer()
  def generated_checked(%__MODULE__{generated_checked: generated_checked}), do: generated_checked

  @spec indexed_checked(t()) :: non_neg_integer()
  def indexed_checked(%__MODULE__{indexed_checked: indexed_checked}), do: indexed_checked

  @spec sources(t()) :: %{generated: non_neg_integer(), indexed: non_neg_integer()}
  def sources(%__MODULE__{} = replay),
    do: %{generated: replay.generated_checked, indexed: replay.indexed_checked}

  @spec skipped_count(t()) :: non_neg_integer()
  def skipped_count(%__MODULE__{skipped: skipped}), do: length(skipped)

  @spec empty() :: t()
  def empty, do: %__MODULE__{generated_checked: 0, indexed_checked: 0, skipped: [], failures: []}
end
