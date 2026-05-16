defmodule Theoria.Inductive.Recursor do
  @moduledoc "Recursor or induction principle declaration in an inductive specification."

  @enforce_keys [:name, :type, :reduction]
  defstruct [:name, :type, :reduction]

  @type t :: %__MODULE__{
          name: atom(),
          type: Theoria.Term.t(),
          reduction: Theoria.Env.Reduction.t()
        }
end
