defmodule Theoria.Level.Solver do
  @moduledoc "Small solver for universe-level ordering constraints."

  alias Theoria.Level
  alias Theoria.Level.{Constraint, Max, Succ}

  @spec leq?(Level.t(), Level.t()) :: boolean()
  def leq?(left, right), do: solve?(Constraint.leq(left, right), MapSet.new())

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

  defp direct_solution?(left, right) do
    Level.equal?(left, right) or Level.zero?(left) or closed_leq?(left, right) or
      symbolic_upper_bound?(left, right)
  end

  defp decompose?(%Succ{level: left}, %Succ{level: right}, seen) do
    solve?(Constraint.leq(left, right), seen)
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

  defp symbolic_upper_bound?(left, right) do
    match?({:ok, _level}, Level.to_integer(left)) and
      not MapSet.equal?(Level.params(right), MapSet.new())
  end
end
