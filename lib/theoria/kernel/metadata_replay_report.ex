defmodule Theoria.Kernel.MetadataReplayReport do
  @moduledoc "Structured metadata/reduction replay assurance report."

  @enforce_keys [:checked, :sources, :failures]
  defstruct [:checked, :sources, :failures]

  @type t :: %__MODULE__{
          checked: non_neg_integer(),
          sources: %{atom() => non_neg_integer()},
          failures: [term()]
        }

  @spec new([{atom(), non_neg_integer(), [term()]}]) :: t()
  def new(entries) when is_list(entries) do
    %__MODULE__{
      checked:
        Enum.reduce(entries, 0, fn {_source, count, _failures}, total -> total + count end),
      sources: Map.new(entries, fn {source, count, _failures} -> {source, count} end),
      failures: Enum.flat_map(entries, fn {_source, _count, failures} -> failures end)
    }
  end

  @spec checked(t()) :: non_neg_integer()
  def checked(%__MODULE__{checked: checked}), do: checked

  @spec source_count(t(), atom()) :: non_neg_integer()
  def source_count(%__MODULE__{sources: sources}, source), do: Map.get(sources, source, 0)

  @spec failure_count(t()) :: non_neg_integer()
  def failure_count(%__MODULE__{failures: failures}), do: length(failures)
end
