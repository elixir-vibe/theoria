defmodule Theoria.LevelTest do
  use ExUnit.Case, async: true

  alias Theoria.Level

  test "converts non-negative integers to closed levels" do
    assert Level.to_integer(Level.from_integer(0)) == {:ok, 0}
    assert Level.to_integer(Level.from_integer(3)) == {:ok, 3}
  end

  test "successor increments closed levels" do
    assert Level.to_integer(Level.succ(Level.from_integer(2))) == {:ok, 3}
  end

  test "max simplifies closed levels" do
    assert Level.max(Level.from_integer(1), Level.from_integer(3)) == Level.from_integer(3)
  end

  test "zero detects the zero level" do
    assert Level.zero?(Level.zero())
    refute Level.zero?(Level.succ(Level.zero()))
  end
end
