defmodule Theoria.Inductive.Index do
  @moduledoc "Named index of an inductive family."

  alias Theoria.Term

  @enforce_keys [:name, :type]
  defstruct [:name, :type]

  @type t :: %__MODULE__{name: atom(), type: Term.t()}
end
