defmodule Theoria.Rewrite.Step do
  @moduledoc "One structural rewrite application with the matched path and optional proof data."

  alias Theoria.Rewrite.Proof.Result, as: ProofResult
  alias Theoria.Rewrite.Rule
  alias Theoria.Term

  @enforce_keys [:rule, :before, :after, :path]
  defstruct [:rule, :before, :after, :path, :proof_result, :substitution]

  @type path_segment :: atom()

  @type t :: %__MODULE__{
          rule: Rule.t(),
          before: Term.t(),
          after: Term.t(),
          path: [path_segment()],
          proof_result: ProofResult.t() | nil,
          substitution: Theoria.Rewrite.Match.substitution() | nil
        }
end
