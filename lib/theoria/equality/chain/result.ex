defmodule Theoria.Equality.Chain.Result do
  @moduledoc "Proof term and strategy selected for an equality chain."

  alias Theoria.Term

  @enforce_keys [:proof, :strategy]
  defstruct [:proof, :strategy]

  @type strategy :: :refl | :single | :transitive | :fallback_defeq
  @type t :: %__MODULE__{proof: Term.t(), strategy: strategy()}
end
