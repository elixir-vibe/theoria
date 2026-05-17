defmodule Theoria.Equation.FixedParams do
  @moduledoc "Minimal descriptor for fixed parameters of compiled equation definitions."

  @enforce_keys [:positions]
  defstruct [:positions]

  @type t :: %__MODULE__{positions: [non_neg_integer()]}

  @doc "Builds a fixed-parameter descriptor."
  @spec new([non_neg_integer()]) :: t()
  def new(positions \\ []) when is_list(positions), do: %__MODULE__{positions: positions}

  @doc "Returns whether an argument position is fixed."
  @spec fixed?(t(), non_neg_integer()) :: boolean()
  def fixed?(%__MODULE__{positions: positions}, position), do: position in positions
end
