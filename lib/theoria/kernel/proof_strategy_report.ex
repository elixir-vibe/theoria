defmodule Theoria.Kernel.ProofStrategyReport do
  @moduledoc "Structured proof-strategy count summary for generated artifacts."

  @enforce_keys [:total, :counts]
  defstruct [:total, :counts]

  @type t :: %__MODULE__{total: non_neg_integer(), counts: %{atom() => non_neg_integer()}}

  @spec new(%{atom() => non_neg_integer()}) :: t()
  def new(counts) when is_map(counts) do
    total = Enum.reduce(counts, 0, fn {_strategy, count}, total -> total + count end)
    %__MODULE__{total: total, counts: counts}
  end
end
