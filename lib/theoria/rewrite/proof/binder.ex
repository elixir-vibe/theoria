defmodule Theoria.Rewrite.Proof.Binder do
  @moduledoc "Boundary helper for binder-path proof lifting attempts."

  alias Theoria.Rewrite.Proof.Capabilities
  alias Theoria.Rewrite.Proof.Capability
  alias Theoria.Rewrite.Step

  @spec explain(Step.t()) :: Capability.t()
  def explain(%Step{path: [:domain]}), do: Capabilities.explain([:domain])
  def explain(%Step{path: [:body]}), do: Capabilities.explain([:body])
  def explain(%Step{path: path}), do: Capabilities.explain(path)
end
