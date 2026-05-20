defmodule Theoria.Spec.Effect do
  @moduledoc """
  Small effect lattice vocabulary for tool-generated safety claims.

  The lattice is deliberately coarse and mirrors the kind of effects Reach and
  similar analyzers report. It is meant for claims such as "this rewrite did not
  introduce stronger effects" rather than full semantic equivalence.
  """

  @type t :: :pure | :read | :write | :io | :send | :exception | :unknown

  @effects [:pure, :read, :write, :io, :send, :exception, :unknown]
  @rank %{pure: 0, read: 1, write: 2, io: 2, send: 2, exception: 2, unknown: 3}

  defmodule Delta do
    @moduledoc "Effect comparison result for one before/after pair."

    @type t :: %__MODULE__{
            before: Theoria.Spec.Effect.t(),
            after: Theoria.Spec.Effect.t(),
            allowed?: boolean()
          }

    @enforce_keys [:before, :after, :allowed?]
    defstruct @enforce_keys

    @doc "Returns true when `after` is no stronger than `before`."
    @spec allowed?(t()) :: boolean()
    def allowed?(%__MODULE__{allowed?: allowed?}), do: allowed?
  end

  @doc "Returns supported effect atoms."
  @spec effects() :: [t()]
  def effects, do: @effects

  @doc "Returns true when `left` is no stronger than `right`."
  @spec leq?(t(), t()) :: boolean()
  def leq?(left, right) when left in @effects and right in @effects do
    Map.fetch!(@rank, left) <= Map.fetch!(@rank, right)
  end

  @doc "Returns true if every after-effect is no stronger than its before-effect."
  @spec no_new_effects?([t()], [t()]) :: boolean()
  def no_new_effects?(before_effects, after_effects)
      when is_list(before_effects) and is_list(after_effects) do
    before_effects
    |> deltas(after_effects)
    |> Enum.all?(&Delta.allowed?/1)
  end

  @doc "Compares before/after effect lists pairwise. Missing sides are treated as `:pure`."
  @spec deltas([t()], [t()]) :: [Delta.t()]
  def deltas(before_effects, after_effects)
      when is_list(before_effects) and is_list(after_effects) do
    before_effects
    |> pad(after_effects)
    |> Enum.map(fn {left, right} ->
      %Delta{before: left, after: right, allowed?: leq?(right, left)}
    end)
  end

  @doc "Returns a coarse join of effects."
  @spec join([t()]) :: t()
  def join([]), do: :pure

  def join(effects) when is_list(effects) do
    Enum.max_by(effects, &Map.fetch!(@rank, &1))
  end

  defp pad(left, right) do
    length = max(length(left), length(right))

    left
    |> pad_to(length)
    |> Enum.zip(pad_to(right, length))
  end

  defp pad_to(values, length), do: values ++ List.duplicate(:pure, length - Kernel.length(values))
end
