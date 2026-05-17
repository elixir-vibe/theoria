defmodule Theoria.Env.Constant do
  @moduledoc "A checked constant or definition in a kernel environment."

  alias Theoria.Term

  @enforce_keys [:type]
  defstruct [
    :type,
    :value,
    kind: :constant,
    reducible?: false,
    universe_params: [],
    reduction: nil,
    metadata: nil
  ]

  @type metadata ::
          Theoria.Env.Inductive.t()
          | Theoria.Env.Constructor.t()
          | Theoria.Env.Recursor.t()
          | Theoria.Env.Matcher.t()
          | Theoria.Equation.Info.t()
          | nil

  @type kind ::
          :constant
          | :axiom
          | :definition
          | :theorem
          | :inductive
          | :constructor
          | :recursor
          | :matcher
  @type t :: %__MODULE__{
          type: Term.t(),
          value: Term.t() | nil,
          kind: kind(),
          reducible?: boolean(),
          universe_params: [atom()],
          reduction: Theoria.Env.Reduction.t() | nil,
          metadata: metadata()
        }
end
