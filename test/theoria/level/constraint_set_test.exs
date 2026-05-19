defmodule Theoria.Level.ConstraintSetTest do
  use ExUnit.Case, async: true

  alias Theoria.Level
  alias Theoria.Level.ConstraintSet

  test "checks explicit universe constraints" do
    u = Level.param(:u)
    v = Level.param(:v)

    set =
      ConstraintSet.new()
      |> ConstraintSet.add_leq(u, Level.max(u, v))
      |> ConstraintSet.add_leq(v, Level.max(u, v))

    assert ConstraintSet.check(set) == :ok
  end

  test "explains unsolved constraints" do
    set = ConstraintSet.add_leq(ConstraintSet.new(), Level.from_integer(1), Level.param(:u))

    assert {:error, [{:unsolved, constraint}]} = ConstraintSet.check(set)
    assert constraint.left == Level.from_integer(1)
    assert [%{constraint: ^constraint, solved?: false}] = ConstraintSet.explain(set)
  end
end
