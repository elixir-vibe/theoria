defmodule Theoria.Rewrite.Proof.Binder do
  @moduledoc """
  Experimental boundary helper for binder-path proof lifting attempts.

  The shape may change before 1.0.
  """

  alias Theoria.Rewrite.Proof.Capabilities
  alias Theoria.Rewrite.Proof.Capability
  alias Theoria.Rewrite.Step

  @spec explain(Step.t()) :: Capability.t()
  def explain(%Step{path: path}), do: Capabilities.explain(path)
end
