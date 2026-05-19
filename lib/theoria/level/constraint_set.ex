defmodule Theoria.Level.ConstraintSet do
  @moduledoc "Explicit collection of universe-level ordering constraints."

  alias Theoria.Level
  alias Theoria.Level.Constraint
  alias Theoria.Level.Solver

  @enforce_keys [:constraints]
  defstruct constraints: []

  @type t :: %__MODULE__{constraints: [Constraint.t()]}
  @type failure :: {:unsolved, Constraint.t()}

  @spec new() :: t()
  def new, do: %__MODULE__{constraints: []}

  @spec add(t(), Constraint.t()) :: t()
  def add(%__MODULE__{constraints: constraints} = set, %Constraint{} = constraint) do
    %{set | constraints: constraints ++ [constraint]}
  end

  @spec add_leq(t(), Level.t(), Level.t()) :: t()
  def add_leq(%__MODULE__{} = set, left, right), do: add(set, Constraint.leq(left, right))

  @spec check(t()) :: :ok | {:error, [failure()]}
  def check(%__MODULE__{constraints: constraints}) do
    failures = Enum.reject(constraints, &Solver.solve?/1)

    case failures do
      [] -> :ok
      failures -> {:error, Enum.map(failures, &{:unsolved, &1})}
    end
  end

  @spec explain(t()) :: [Solver.Explanation.t()]
  def explain(%__MODULE__{constraints: constraints}), do: Enum.map(constraints, &Solver.explain/1)
end
