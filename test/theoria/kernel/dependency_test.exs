defmodule Theoria.Kernel.DependencyTest do
  use ExUnit.Case, async: true

  alias Theoria.Kernel
  alias Theoria.Prelude

  test "collects declaration dependencies from type and value" do
    {:ok, env} = Prelude.env()

    assert {:ok, dependencies} = Kernel.dependencies(env, :nat_add)

    assert MapSet.subset?(
             MapSet.new([:Nat, :nat_rec, :succ]),
             dependencies
           )
  end

  test "collects theorem-like definition dependencies" do
    {:ok, env} = Prelude.env()

    assert {:ok, dependencies} = Kernel.dependencies(env, :list_length)

    assert MapSet.subset?(
             MapSet.new([:List, :Nat, :list_rec, :zero, :succ]),
             dependencies
           )
  end

  test "unknown declaration dependency lookup fails" do
    {:ok, env} = Prelude.env()

    assert {:error, error} = Kernel.dependencies(env, :missing)
    assert error.reason == :unknown_constant
  end
end
