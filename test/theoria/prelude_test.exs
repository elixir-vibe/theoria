defmodule Theoria.PreludeTest do
  use ExUnit.Case, async: true

  alias Theoria.Kernel
  alias Theoria.Library.{Bool, List, Logic, Nat}
  alias Theoria.Prelude
  alias Theoria.Theorem

  import Theoria.Term

  test "loads the built-in libraries into one environment" do
    assert {:ok, env} = Prelude.env()

    for name <- [
          :False,
          :True,
          :and,
          :Bool,
          true,
          false,
          :Nat,
          :zero,
          :succ
        ] do
      assert {:ok, _type} = Kernel.infer(env, const(name))
    end

    for name <- [:bool_rec, :nat_rec, :nat_ind] do
      assert {:ok, _type} = Kernel.infer(env, const(name, [1]))
    end

    for name <- [:List, :list_nil, :list_cons] do
      assert {:ok, _type} = Kernel.infer(env, const(name, [1]))
    end

    assert {:ok, _type} = Kernel.infer(env, const(:list_rec, [1, 1]))
  end

  test "top-level convenience returns the prelude environment" do
    assert {:ok, env} = Theoria.prelude_env()
    assert {:ok, _type} = Kernel.infer(env, const(:list_length, [1]))
  end

  test "checks all built-in theorem modules under the prelude" do
    {:ok, env} = Prelude.env()

    for module <- [Logic.Theorems, Bool.Theorems, Nat.Theorems, List.Theorems] do
      assert {:ok, theorems} = Theorem.check_all(module, env)
      assert length(theorems) == length(module.__theoria_theorems__())
    end
  end
end
