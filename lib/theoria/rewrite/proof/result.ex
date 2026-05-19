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

  @spec checked?(t() | nil) :: boolean()
  def checked?(%__MODULE__{status: :checked}), do: true
  def checked?(_result), do: false

  @spec proof(t() | nil) :: Term.t() | nil
  def proof(%__MODULE__{proof: proof}), do: proof
  def proof(nil), do: nil

  @spec status(t() | nil) :: status() | nil
  def status(%__MODULE__{status: status}), do: status
  def status(nil), do: nil

  @spec capability(t() | nil) :: Capability.t() | nil
  def capability(%__MODULE__{capability: capability}), do: capability
  def capability(nil), do: nil

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
