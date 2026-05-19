defmodule Theoria.Simp.Result do
  @moduledoc "Result of repeated simplification, including optional proof artifact data."

  alias Theoria.Equation.Realized
  alias Theoria.Simp.Step
  alias Theoria.Term

  @enforce_keys [:input, :term, :steps, :stopped]
  defstruct [:input, :term, :steps, :stopped, :type, :proof, :proof_strategy, :realized]

  @type t :: %__MODULE__{
          input: Term.t(),
          term: Term.t(),
          steps: [Step.t()],
          stopped: :normal | :fuel,
          type: Term.t() | nil,
          proof: Term.t() | nil,
          proof_strategy: atom() | nil,
          realized: Realized.t() | nil
        }

  @spec proof_checked?(t()) :: boolean()
  def proof_checked?(%__MODULE__{realized: realized}), do: not is_nil(realized)

  @spec proof_strategy(t()) :: atom() | nil
  def proof_strategy(%__MODULE__{proof_strategy: strategy}), do: strategy
end
