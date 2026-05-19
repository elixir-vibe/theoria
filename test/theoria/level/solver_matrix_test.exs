defmodule Theoria.Level.SolverMatrixTest do
  use ExUnit.Case, async: true

  alias Theoria.Level

  test "symbolic universe solver matrix" do
    u = Level.param(:u)
    v = Level.param(:v)
    w = Level.param(:w)

    accepted = [
      {u, u},
      {u, Level.max(u, v)},
      {v, Level.max(u, v)},
      {u, Level.succ(u)},
      {Level.succ(u), Level.succ(Level.max(u, v))},
      {Level.max(u, v), Level.max(v, u)},
      {Level.max(u, Level.max(v, w)), Level.max(w, Level.max(u, v))}
    ]

    rejected = [
      {Level.succ(u), u},
      {Level.from_integer(1), u},
      {Level.max(Level.succ(u), v), Level.max(u, v)},
      {Level.max(u, v), u}
    ]

    for {left, right} <- accepted do
      assert Level.leq?(left, right), "expected #{inspect(left)} <= #{inspect(right)}"
    end

    for {left, right} <- rejected do
      refute Level.leq?(left, right),
             "expected #{inspect(left)} <= #{inspect(right)} to be rejected"
    end
  end
end
