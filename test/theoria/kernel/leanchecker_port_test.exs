defmodule Theoria.Kernel.LeancheckerPortTest do
  use ExUnit.Case, async: true

  alias Theoria.Env
  alias Theoria.Env.Constant
  alias Theoria.Kernel
  alias Theoria.Library.Logic

  import Theoria.Term

  test "validation catches replaced dependency types" do
    {:ok, env} = Logic.env()
    {:ok, env} = Kernel.add_theorem(env, :truth, const(:True), const(:true_intro))

    corrupted_constants =
      Map.put(env.constants, :true_intro, %Constant{type: const(:False), kind: :constant})

    corrupted_env = %{env | constants: corrupted_constants}

    assert {:error, error} = Kernel.validate_env(corrupted_env)
    assert error.reason == :type_mismatch
  end

  test "validation catches raw theorem declarations with invalid proofs" do
    {:ok, env} = Logic.env()
    env = Env.put_theorem(env, :bad_truth, const(:True), const(:False))

    assert {:error, error} = Kernel.validate_env(env)
    assert error.reason == :type_mismatch
  end

  test "validation catches raw axiom declarations with invalid types" do
    env = %Env{
      constants: %{bad_axiom: %Constant{type: const(:Missing), kind: :axiom}},
      declarations: [:bad_axiom]
    }

    assert {:error, error} = Kernel.validate_env(env)
    assert error.reason == :unknown_constant
  end

  test "validation catches declarations whose kind/value shape is invalid" do
    env = %Env{
      constants: %{bad_theorem: %Constant{type: sort(0), kind: :theorem, value: nil}},
      declarations: [:bad_theorem]
    }

    assert {:error, error} = Kernel.validate_env(env)
    assert error.reason == :invalid_declaration
  end
end
