defmodule Theoria.Inductive.Parameter do
  @moduledoc "Named parameter of an inductive family."

  alias Theoria.Term

  @enforce_keys [:name, :type]
  defstruct [:name, :type]

  @type t :: %__MODULE__{name: atom(), type: Term.t()}
end
