defprotocol Theoria.Spec.Claim do
  @moduledoc """
  Protocol for structural claims produced by `Theoria.Spec` vocabularies.

  Claim structs are not kernel proofs by themselves. The protocol gives reports
  and tool integrations a common way to ask whether a structural witness is
  valid, what kind of claim it represents, and why it failed.
  """

  @doc "Returns the claim kind."
  @spec kind(t()) :: atom()
  def kind(claim)

  @doc "Returns true when the structural claim is valid."
  @spec valid?(t()) :: boolean()
  def valid?(claim)

  @doc "Returns the failure reason, or `nil` when valid."
  @spec reason(t()) :: term()
  def reason(claim)
end
