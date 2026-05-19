defmodule Theoria.Rewrite.Proof.Result do
  @moduledoc "Proof outcome attached to a structural rewrite or simplification step."

  alias Theoria.Rewrite.Proof.Capability
  alias Theoria.Term

  @enforce_keys [:status, :capability]
  defstruct [:status, :capability, proof: nil]

  @type status ::
          :checked
          | :not_requested
          | :missing_rule_proof
          | :unsupported_path
          | :kernel_rejected

  @type t :: %__MODULE__{
          proof: Term.t() | nil,
          status: status(),
          capability: Capability.t()
        }

  @spec checked(Term.t(), Capability.t()) :: t()
  def checked(proof, capability),
    do: %__MODULE__{proof: proof, status: :checked, capability: capability}

  @spec rejected(status(), Capability.t()) :: t()
  def rejected(status, capability), do: %__MODULE__{status: status, capability: capability}

  @spec not_requested() :: t()
  def not_requested do
    %__MODULE__{
      status: :not_requested,
      capability: %Capability{
        supported?: false,
        reason: :not_requested,
        description: "proof construction was not requested"
      }
    }
  end
end
