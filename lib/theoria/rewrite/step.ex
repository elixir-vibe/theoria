defmodule Theoria.Rewrite.Step do
  @moduledoc "One structural rewrite application with the matched path and optional proof data."

  alias Theoria.Rewrite.Rule
  alias Theoria.Term

  @enforce_keys [:rule, :before, :after, :path]
  defstruct [:rule, :before, :after, :path, :proof, :proof_status, :substitution]

  @type path_segment :: atom()

  @type t :: %__MODULE__{
          rule: Rule.t(),
          before: Term.t(),
          after: Term.t(),
          path: [path_segment()],
          proof: Term.t() | nil,
          proof_status:
            :checked
            | :not_requested
            | :missing_rule_proof
            | :unsupported_path
            | :kernel_rejected
            | nil,
          substitution: Theoria.Rewrite.Match.substitution() | nil
        }
end
