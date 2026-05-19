defmodule Theoria.Simp.Step do
  @moduledoc "Experimental before 1.0; the shape may change. One simplifier rewrite step for tracing and debugging."

  alias Theoria.Rewrite.Proof.Result, as: ProofResult
  alias Theoria.Term

  @enforce_keys [:rule, :before, :after]
  defstruct [:rule, :before, :after, :proof_result, path: [], source: :equation]

  @type t :: %__MODULE__{
          rule: atom(),
          before: Term.t(),
          after: Term.t(),
          proof_result: ProofResult.t() | nil,
          path: [atom()],
          source: atom()
        }

  @spec proof_status(t()) :: ProofResult.status() | nil
  def proof_status(%__MODULE__{proof_result: proof_result}), do: ProofResult.status(proof_result)

  @spec proof_checked?(t()) :: boolean()
  def proof_checked?(%__MODULE__{proof_result: proof_result}),
    do: ProofResult.checked?(proof_result)
end
