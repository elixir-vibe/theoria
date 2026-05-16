defmodule Theoria.Kernel.TrustReport do
  @moduledoc "Dependency and trust summary for an environment declaration."

  @enforce_keys [
    :name,
    :kind,
    :direct_dependencies,
    :transitive_dependencies,
    :axioms,
    :primitive_dependencies,
    :theorem_dependencies
  ]
  defstruct [
    :name,
    :kind,
    :direct_dependencies,
    :transitive_dependencies,
    :axioms,
    :primitive_dependencies,
    :theorem_dependencies
  ]

  @type t :: %__MODULE__{
          name: atom(),
          kind: Theoria.Env.Constant.kind(),
          direct_dependencies: MapSet.t(atom()),
          transitive_dependencies: MapSet.t(atom()),
          axioms: MapSet.t(atom()),
          primitive_dependencies: MapSet.t(atom()),
          theorem_dependencies: MapSet.t(atom())
        }
end
