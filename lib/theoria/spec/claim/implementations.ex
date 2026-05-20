defimpl Theoria.Spec.Claim, for: Theoria.Spec.Finite.SubsetClaim do
  def kind(_claim), do: :finite_subset
  def valid?(claim), do: claim.valid?
  def reason(%{missing: []}), do: nil
  def reason(claim), do: {:missing, claim.missing}
end

defimpl Theoria.Spec.Claim, for: Theoria.Spec.Finite.NoNewClaim do
  def kind(_claim), do: :finite_no_new
  def valid?(claim), do: claim.valid?
  def reason(%{added: []}), do: nil
  def reason(claim), do: {:added, claim.added}
end

defimpl Theoria.Spec.Claim, for: Theoria.Spec.Graph.PathClaim do
  def kind(_claim), do: :graph_path
  def valid?(claim), do: claim.valid?
  def reason(claim), do: claim.reason
end

defimpl Theoria.Spec.Claim, for: Theoria.Spec.Effect.Delta do
  def kind(_claim), do: :effect_delta
  def valid?(claim), do: claim.allowed?
  def reason(%{allowed?: true}), do: nil
  def reason(claim), do: {:stronger_effect, claim.before, claim.after}
end

defimpl Theoria.Spec.Claim, for: Theoria.Spec.Typespec.Compatibility do
  def kind(_claim), do: :typespec_compatibility
  def valid?(claim), do: claim.compatible?
  def reason(claim), do: claim.reason
end
