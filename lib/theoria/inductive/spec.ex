defmodule Theoria.Inductive.Spec do
  @moduledoc "Structured description of an inductive family."

  alias Theoria.Inductive.{Constructor, Recursor}
  alias Theoria.Term

  @enforce_keys [:name, :type, :constructors]
  defstruct [
    :name,
    :type,
    constructors: [],
    universe_params: [],
    parameters: [],
    indices: [],
    recursors: []
  ]

  @type t :: %__MODULE__{
          name: atom(),
          type: Term.t(),
          constructors: [Constructor.t()],
          universe_params: [atom()],
          parameters: [Term.t()],
          indices: [Term.t()],
          recursors: [Recursor.t()]
        }
end
