defmodule Theoria.Kernel.ProofStrategyReport do
  @moduledoc "Structured proof-strategy count summary for generated artifacts."

  @enforce_keys [:total, :counts]
  defstruct [:total, :counts]

  @type t :: %__MODULE__{total: non_neg_integer(), counts: %{atom() => non_neg_integer()}}

  @spec total(t()) :: non_neg_integer()
  def total(%__MODULE__{total: total}), do: total

  @spec counts(t()) :: %{atom() => non_neg_integer()}
  def counts(%__MODULE__{counts: counts}), do: counts

  @spec count(t(), atom()) :: non_neg_integer()
  def count(%__MODULE__{counts: counts}, strategy), do: Map.get(counts, strategy, 0)

  @spec new(%{atom() => non_neg_integer()}) :: t()
  def new(counts) when is_map(counts) do
    total = Enum.reduce(counts, 0, fn {_strategy, count}, total -> total + count end)
    %__MODULE__{total: total, counts: counts}
  end
end
