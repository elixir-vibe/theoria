defmodule Theoria.Rewrite.Proof.EqRec do
  @moduledoc "Boundary helper for EqRec-path proof lifting attempts."

  alias Theoria.Rewrite.Proof.Capabilities
  alias Theoria.Rewrite.Proof.Capability
  alias Theoria.Rewrite.Step

  @spec explain(Step.t()) :: Capability.t()
  def explain(%Step{path: [:proof]}), do: Capabilities.explain([:proof])
  def explain(%Step{path: [:base]}), do: Capabilities.explain([:base])
  def explain(%Step{path: path}), do: Capabilities.explain(path)
end
