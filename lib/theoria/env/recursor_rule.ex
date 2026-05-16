defmodule Theoria.Env.RecursorRule do
  @moduledoc "Lean-style iota-reduction rule metadata for a recursor constructor case."

  alias Theoria.Term

  @enforce_keys [:constructor, :field_count]
  defstruct [:constructor, :field_count, :rhs]

  @type t :: %__MODULE__{
          constructor: atom(),
          field_count: non_neg_integer(),
          rhs: Term.t() | nil
        }
end
