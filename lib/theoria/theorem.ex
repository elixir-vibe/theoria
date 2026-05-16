defmodule Theoria.Theorem do
  @moduledoc "A theorem accepted by the trusted kernel."

  alias Theoria.Term

  @enforce_keys [:name, :type, :proof]
  defstruct [:name, :type, :proof]

  @type t :: %__MODULE__{name: atom(), type: Term.t(), proof: Term.t()}
end
