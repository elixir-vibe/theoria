defmodule Theoria.Simp.Step do
  @moduledoc "Experimental/internal API for 0.2; subject to change before 0.3. One simplifier rewrite step for tracing and debugging."

  alias Theoria.Term

  @enforce_keys [:rule, :before, :after]
  defstruct [:rule, :before, :after, :proof, :proof_status, path: [], source: :equation]

  @type t :: %__MODULE__{
          rule: atom(),
          before: Term.t(),
          after: Term.t(),
          proof: Term.t() | nil,
          proof_status:
            :checked
            | :not_requested
            | :missing_rule_proof
            | :unsupported_path
            | :kernel_rejected
            | nil,
          path: [atom()],
          source: atom()
        }
end
