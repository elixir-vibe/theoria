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

    assert [%{constraint: ^constraint, status: :unsolved, rule: :none}] =
             ConstraintSet.explain(set)
  end

  test "encodes explanations as JSON" do
    set = ConstraintSet.add_leq(ConstraintSet.new(), Level.zero(), Level.param(:u))

    assert Jason.encode!(ConstraintSet.explain(set)) =~ "\"rule\":\"zero\""
  end

  test "explains solved constraints with rules" do
    u = Level.param(:u)
    v = Level.param(:v)
    set = ConstraintSet.add_leq(ConstraintSet.new(), u, Level.max(u, v))

    assert [%{status: :solved, rule: :max_left}] = ConstraintSet.explain(set)
  end
end
