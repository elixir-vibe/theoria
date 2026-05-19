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

  test "does not treat parameters as symbolic upper bounds for closed levels" do
    u = Level.param(:u)

    refute Level.leq?(Level.from_integer(1), u)
    assert Level.leq?(Level.from_integer(1), Level.succ(u))
  end

  test "normalizes max modulo commutativity and associativity" do
    u = Level.param(:u)
    v = Level.param(:v)
    w = Level.param(:w)

    assert Level.equal?(Level.max(u, v), Level.max(v, u))
    assert Level.equal?(Level.max(Level.max(u, v), w), Level.max(u, Level.max(w, v)))
  end

  test "solves max upper bounds" do
    u = Level.param(:u)
    v = Level.param(:v)

    assert Level.leq?(u, Level.max(v, u))
    assert Level.leq?(Level.max(u, v), Level.max(v, u))
    refute Level.leq?(Level.max(Level.succ(u), v), u)
  end
end
