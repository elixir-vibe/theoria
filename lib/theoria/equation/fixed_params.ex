defmodule Theoria.Equation.FixedParams do
  @moduledoc "Experimental/internal API for 0.1; subject to change before 0.2. Minimal descriptor for fixed parameters of compiled equation definitions."

  @enforce_keys [:positions]
  defstruct [:positions]

  @type t :: %__MODULE__{positions: [non_neg_integer()]}

  @doc "Builds a fixed-parameter descriptor."
  @spec new([non_neg_integer()]) :: t()
  def new(positions \\ []) when is_list(positions) do
    positions
    |> Enum.uniq()
    |> Enum.sort()
    |> then(&%__MODULE__{positions: &1})
  end

  @doc "Derives fixed parameters from a definition signature."
  @spec analyze(map()) :: {:ok, t()} | {:error, term()}
  def analyze(%{parameters: parameters, rec_arg_pos: rec_arg_pos})
      when is_list(parameters) and is_integer(rec_arg_pos) and rec_arg_pos >= 0 do
    parameters
    |> Enum.with_index()
    |> Enum.map(fn {_parameter, position} -> position end)
    |> new()
    |> then(&{:ok, &1})
  end

  def analyze(%{rec_arg_pos: rec_arg_pos}), do: {:error, {:invalid_rec_arg_pos, rec_arg_pos}}

  @doc "Returns whether an argument position is fixed."
  @spec fixed?(t(), non_neg_integer()) :: boolean()
  def fixed?(%__MODULE__{positions: positions}, position), do: position in positions
end
