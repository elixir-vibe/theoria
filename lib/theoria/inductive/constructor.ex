defmodule Theoria.Inductive.Constructor do
  @moduledoc "Constructor declaration in an inductive specification."

  @enforce_keys [:name, :type]
  defstruct [:name, :type]

  @type t :: %__MODULE__{name: atom(), type: Theoria.Term.t()}
end
