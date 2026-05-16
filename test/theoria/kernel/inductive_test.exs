defmodule Theoria.Kernel.InductiveTest do
  use ExUnit.Case, async: true

  alias Theoria.Env
  alias Theoria.Inductive
  alias Theoria.Kernel
  alias Theoria.Library.{Bool, Nat}

  test "admits inductive specs through the kernel" do
    assert {:ok, env} = Kernel.add_inductive(Env.new(), Bool.inductive_spec())
    assert Inductive.verify_env(env, Bool.inductive_spec()) == :ok
  end

  test "rejects duplicate inductive admission" do
    {:ok, env} = Kernel.add_inductive(Env.new(), Nat.inductive_spec())

    assert {:error, error} = Kernel.add_inductive(env, Nat.inductive_spec())
    assert error.reason == :duplicate_declaration
    assert error.details == [name: :Nat]
  end
end
