defmodule Theoria.Normalize.Fuel do
  @moduledoc "Shared fuel budget for normalization."

  alias Theoria.Error

  @default_max_steps 10_000

  @enforce_keys [:remaining_steps, :max_steps]
  defstruct [:remaining_steps, :max_steps]

  @type t :: %__MODULE__{
          remaining_steps: non_neg_integer(),
          max_steps: pos_integer()
        }

  @doc "Builds a fuel budget from normalization options."
  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    max_steps = Keyword.get(opts, :max_steps, @default_max_steps)
    %__MODULE__{remaining_steps: max_steps, max_steps: max_steps}
  end

  @doc "Consumes one normalization step."
  @spec spend(t()) :: {:ok, t()} | {:error, Error.t()}
  def spend(%__MODULE__{remaining_steps: remaining_steps, max_steps: max_steps})
      when remaining_steps <= 0 do
    {:error, %Error{reason: :normalization_limit, details: [max_steps: max_steps]}}
  end

  def spend(%__MODULE__{remaining_steps: remaining_steps} = fuel) do
    {:ok, %{fuel | remaining_steps: remaining_steps - 1}}
  end
end
