defmodule Theoria.Level.Constraint do
  @moduledoc "Universe-level ordering constraint."

  alias Theoria.Level

  @enforce_keys [:left, :right]
  defstruct [:left, :right]

  @type t :: %__MODULE__{left: Level.t(), right: Level.t()}

  @spec leq(Level.t(), Level.t()) :: t()
  def leq(left, right),
    do: %__MODULE__{left: Level.normalize(left), right: Level.normalize(right)}
end
