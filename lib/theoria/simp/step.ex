defmodule Theoria.Simp.Step do
  @moduledoc "One simplifier rewrite step for tracing and debugging."

  alias Theoria.Term

  @enforce_keys [:rule, :before, :after]
  defstruct [:rule, :before, :after, source: :equation]

  @type t :: %__MODULE__{
          rule: atom(),
          before: Term.t(),
          after: Term.t(),
          source: atom()
        }
end
