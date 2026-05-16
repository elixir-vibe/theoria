defmodule Theoria.Kernel.EnvironmentIntegrityTest do
  use ExUnit.Case, async: true

  alias Theoria.Env
  alias Theoria.Kernel

  import Theoria.Term

  test "rejects duplicate constants" do
    assert {:ok, env} = Kernel.add_constant(Env.new(), :A, sort(0))
    assert {:error, error} = Kernel.add_constant(env, :A, sort(0))

    assert error.reason == :duplicate_declaration
    assert Exception.message(error) == "duplicate declaration: A"
  end

  test "rejects definition that duplicates a constant" do
    assert {:ok, env} = Kernel.add_constant(Env.new(), :A, sort(0))
    assert {:error, error} = Kernel.add_definition(env, :A, sort(0), sort(0))

    assert error.reason == :duplicate_declaration
  end

  test "rejects constant that duplicates a definition" do
    assert {:ok, env} = Kernel.add_definition(Env.new(), :A, sort(1), sort(0))
    assert {:error, error} = Kernel.add_constant(env, :A, sort(1))

    assert error.reason == :duplicate_declaration
  end
end
