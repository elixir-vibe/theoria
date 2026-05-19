defmodule Theoria.Level.Solver do
  @moduledoc "Small solver for universe-level ordering constraints."

  alias Theoria.Level
  alias Theoria.Level.{Constraint, Max, Succ}
  alias Theoria.Level.Solver.Explanation

  @spec leq?(Level.t(), Level.t()) :: boolean()
  def leq?(left, right), do: solve?(Constraint.leq(left, right))

  @spec solve?(Constraint.t()) :: boolean()
  def solve?(%Constraint{} = constraint), do: solve?(constraint, MapSet.new())

  @spec explain(Constraint.t()) :: Explanation.t()
  def explain(%Constraint{} = constraint) do
    {status, rule} = explain_constraint(constraint.left, constraint.right)
    %Explanation{constraint: constraint, status: status, rule: rule}
  end

  defp solve?(%Constraint{} = constraint, seen) do
    key = {constraint.left, constraint.right}

    if MapSet.member?(seen, key) do
      false
    else
      solve_unseen?(constraint, MapSet.put(seen, key))
    end
  end

  defp solve_unseen?(%Constraint{left: left, right: right}, seen) do
    direct_solution?(left, right) or decompose?(left, right, seen)
  end

  defp explain_constraint(left, right) do
    cond do
      Level.equal?(left, right) -> {:solved, :reflexive}
      Level.zero?(left) -> {:solved, :zero}
      closed_leq?(left, right) -> {:solved, :closed}
      true -> explain_decomposition(left, right)
    end
  end

  defp explain_decomposition(%Succ{} = left, %Succ{} = right) do
    if decompose?(left, right, MapSet.new()), do: {:solved, :succ}, else: {:unsolved, :none}
  end

  defp explain_decomposition(left, %Succ{} = right) do
    if decompose?(left, right, MapSet.new()), do: {:solved, :succ_right}, else: {:unsolved, :none}
  end

  defp explain_decomposition(%Max{} = left, right) do
    if decompose?(left, right, MapSet.new()), do: {:solved, :max_upper}, else: {:unsolved, :none}
  end

  defp explain_decomposition(left, %Max{} = right) do
    cond do
      solve?(Constraint.leq(left, right.left)) -> {:solved, :max_left}
      solve?(Constraint.leq(left, right.right)) -> {:solved, :max_right}
      true -> {:unsolved, :none}
    end
  end

  defp explain_decomposition(_left, _right), do: {:unsolved, :none}

  defp direct_solution?(left, right) do
    Level.equal?(left, right) or Level.zero?(left) or closed_leq?(left, right)
  end

  defp decompose?(%Succ{level: left}, %Succ{level: right}, seen) do
    solve?(Constraint.leq(left, right), seen)
  end

  defp decompose?(left, %Succ{level: right}, seen) do
    solve?(Constraint.leq(left, right), seen) or Level.equal?(left, right)
  end

  defp decompose?(%Max{left: left_part, right: right_part}, right, seen) do
    solve?(Constraint.leq(left_part, right), seen) and
      solve?(Constraint.leq(right_part, right), seen)
  end

  defp decompose?(left, %Max{left: left_part, right: right_part}, seen) do
    solve?(Constraint.leq(left, left_part), seen) or
      solve?(Constraint.leq(left, right_part), seen)
  end

  defp decompose?(_left, _right, _seen), do: false

  defp closed_leq?(left, right) do
    case {Level.to_integer(left), Level.to_integer(right)} do
      {{:ok, left}, {:ok, right}} -> left <= right
      _other -> false
    end
  end
end
