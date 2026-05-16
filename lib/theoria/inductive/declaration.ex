defmodule Theoria.Inductive.Declaration do
  @moduledoc "Generated declaration plan for an inductive specification."

  @enforce_keys [:name, :type, :kind]
  defstruct [:name, :type, :kind, universe_params: [], reduction: nil, metadata: nil]

  @type kind :: :inductive | :constructor | :recursor

  @type t :: %__MODULE__{
          name: atom(),
          type: Theoria.Term.t(),
          kind: kind(),
          universe_params: [atom()],
          reduction: Theoria.Env.Reduction.t() | nil,
          metadata: Theoria.Env.Constant.metadata()
        }
end
