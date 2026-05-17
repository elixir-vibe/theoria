defmodule Theoria.Level.SolverTest do
  use ExUnit.Case, async: true

  alias Theoria.Level

  test "solves closed universe inequalities" do
    assert Level.leq?(Level.from_integer(1), Level.from_integer(2))
    refute Level.leq?(Level.from_integer(2), Level.from_integer(1))
  end

  test "solves successor inequalities structurally" do
    u = Level.param(:u)
    v = Level.param(:v)

    assert Level.leq?(Level.succ(u), Level.succ(u))
    refute Level.leq?(Level.succ(u), Level.succ(v))
  end

  test "solves max upper bounds" do
    u = Level.param(:u)
    v = Level.param(:v)

    assert Level.leq?(u, Level.max(v, u))
    assert Level.leq?(Level.max(u, v), Level.max(v, u))
    refute Level.leq?(Level.max(Level.succ(u), v), u)
  end
end
