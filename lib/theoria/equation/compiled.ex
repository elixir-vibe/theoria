defmodule Theoria.Equation.Compiled do
  @moduledoc "Result of compiling constructor equations, including generated metadata."

  alias Theoria.Equation.{Clause, FixedParams, MatcherInfo, Schema}
  alias Theoria.Term

  @enforce_keys [:body, :clauses, :schema, :matcher, :rec_arg_pos, :fixed_params]
  defstruct [:body, :clauses, :schema, :matcher, :rec_arg_pos, :fixed_params]

  @type t :: %__MODULE__{
          body: Term.t(),
          clauses: [Clause.t()],
          schema: Schema.t(),
          matcher: MatcherInfo.t(),
          rec_arg_pos: non_neg_integer(),
          fixed_params: FixedParams.t()
        }
end
