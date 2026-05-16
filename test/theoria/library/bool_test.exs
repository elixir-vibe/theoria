defmodule Theoria.Library.BoolTest do
  use ExUnit.Case, async: true

  alias Theoria.Kernel
  alias Theoria.Library.Bool

  import Theoria.Term

  test "extends an environment with boolean declarations" do
    assert {:ok, env} = Bool.env()

    for name <- [:Bool, true, false, :bool_not, :bool_and, :bool_or] do
      assert {:ok, _type} = Kernel.infer(env, const(name))
    end

    assert {:ok, _type} = Kernel.infer(env, const(:bool_rec, [1]))
    assert {:ok, _type} = Kernel.infer(env, const(:bool_ind, [1]))
  end

  test "Bool lives in Type 0, distinct from Prop" do
    {:ok, env} = Bool.env()

    assert {:ok, type} = Kernel.infer(env, const(:Bool))
    assert type == sort(1)
  end
end
