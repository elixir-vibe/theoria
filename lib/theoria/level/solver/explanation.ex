defmodule Theoria.Level.Solver.Explanation do
  @moduledoc "Structured explanation for one universe-constraint solver result."

  alias Theoria.Level.Constraint

  @enforce_keys [:constraint, :status, :rule]
  defstruct [:constraint, :status, :rule]

  @type status :: :solved | :unsolved
  @type rule ::
          :reflexive
          | :zero
          | :closed
          | :succ
          | :succ_right
          | :max_upper
          | :max_left
          | :max_right
          | :none
  @type t :: %__MODULE__{constraint: Constraint.t(), status: status(), rule: rule()}
end
