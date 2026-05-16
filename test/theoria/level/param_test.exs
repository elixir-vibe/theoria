defmodule Theoria.Level.ParamTest do
  use ExUnit.Case, async: true

  alias Theoria.Level

  test "collects universe parameters" do
    level = Level.max(Level.succ(Level.param(:u)), Level.param(:v))

    assert Level.params(level) == MapSet.new([:u, :v])
  end

  test "substitutes universe parameters" do
    level = Level.succ(Level.param(:u))

    assert Level.subst(level, %{u: Level.from_integer(2)}) == Level.from_integer(3)
  end

  test "normalizes max with parameters" do
    u = Level.param(:u)

    assert Level.max(u, u) == u
    assert Level.max(Level.zero(), u) == u
    assert Level.max(u, Level.zero()) == u
  end

  test "integer conversion fails for open levels" do
    assert Level.to_integer(Level.param(:u)) == :error
    assert Level.to_integer(Level.succ(Level.param(:u))) == :error
  end
end
