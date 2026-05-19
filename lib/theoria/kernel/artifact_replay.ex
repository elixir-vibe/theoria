defmodule Theoria.Kernel.ArtifactReplay do
  @moduledoc "Summary for replaying environments extended with generated artifacts."

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

  @spec skipped_count(t()) :: non_neg_integer()
  def skipped_count(%__MODULE__{skipped: skipped}), do: length(skipped)

  @spec empty() :: t()
  def empty, do: %__MODULE__{generated_checked: 0, indexed_checked: 0, skipped: [], failures: []}
end
