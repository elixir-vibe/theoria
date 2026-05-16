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

  test "tracks declaration insertion order" do
    assert {:ok, env} = Kernel.add_constant(Env.new(), :A, sort(0))
    assert {:ok, env} = Kernel.add_constant(env, :B, sort(0))
    assert {:ok, env} = Kernel.add_definition(env, :C, sort(1), sort(0))

    assert Env.declarations(env) == [:A, :B, :C]
  end

  test "validates a checked environment" do
    assert {:ok, env} = Kernel.add_constant(Env.new(), :A, sort(0))
    assert {:ok, env} = Kernel.add_definition(env, :id_type, sort(1), sort(0))

    assert {:ok, checked_env} = Kernel.validate_env(env)
    assert Env.declarations(checked_env) == [:A, :id_type]
  end

  test "validation rejects malformed constant types inserted outside the kernel" do
    env = Env.new() |> Env.put_constant(:bad, const(:Missing))

    assert {:error, error} = Kernel.validate_env(env)
    assert error.reason == :unknown_constant
  end

  test "validation rejects malformed definition values inserted outside the kernel" do
    env = Env.new() |> Env.put_definition(:bad, sort(0), sort(1))

    assert {:error, error} = Kernel.validate_env(env)
    assert error.reason == :type_mismatch
  end

  test "validation catches dependency ordering problems" do
    env =
      %Env{}
      |> Env.put_constant(:later, const(:Earlier))
      |> Env.put_constant(:Earlier, sort(0))

    assert {:error, error} = Kernel.validate_env(env)
    assert error.reason == :unknown_constant
  end
end
