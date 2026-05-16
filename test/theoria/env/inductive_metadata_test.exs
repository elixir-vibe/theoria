defmodule Theoria.Env.InductiveMetadataTest do
  use ExUnit.Case, async: true

  alias Theoria.Env
  alias Theoria.Env.Constant
  alias Theoria.Kernel
  alias Theoria.Library.Nat

  test "fetches lean-style inductive metadata" do
    {:ok, env} = Nat.env()

    assert Env.inductive?(env, :Nat)
    assert Env.constructor?(env, :succ)
    assert Env.recursor?(env, :nat_rec)

    assert {:ok, %Theoria.Env.Inductive{num_params: 0, num_indices: 0}} =
             Env.fetch_inductive(env, :Nat)

    assert {:ok, %Theoria.Env.Constructor{num_fields: 1, constructor_index: 1}} =
             Env.fetch_constructor(env, :succ)

    assert {:ok, %Theoria.Env.Recursor{num_motives: 1, num_minors: 2}} =
             Env.fetch_recursor(env, :nat_ind)

    refute Env.constructor?(env, :Nat)
    assert Env.fetch_recursor(env, :succ) == :error
  end

  test "environment validation rejects inductive declarations stored as ordinary constants" do
    {:ok, env} = Nat.env()

    env =
      update_constant(env, :Nat, fn %Constant{} = constant ->
        %Constant{constant | kind: :constant}
      end)

    assert {:error, error} = Kernel.validate_env(env)
    assert error.reason == :invalid_declaration
  end

  test "environment validation rejects mismatched constructor kind and metadata" do
    {:ok, env} = Nat.env()

    env =
      update_constant(env, :succ, fn %Constant{} = constant ->
        %Constant{constant | kind: :recursor}
      end)

    assert {:error, error} = Kernel.validate_env(env)
    assert error.reason == :invalid_declaration
  end

  test "environment validation rejects iota marker on non-recursor declaration" do
    {:ok, env} = Nat.env()
    recursor = env.constants.nat_rec.metadata

    env =
      update_constant(env, :succ, fn %Constant{} = constant ->
        %Constant{constant | reduction: %Theoria.Env.Reduction.Iota{}, metadata: recursor}
      end)

    assert {:error, error} = Kernel.validate_env(env)
    assert error.reason == :invalid_declaration
  end

  defp update_constant(%Env{constants: constants} = env, name, fun) do
    constant = Map.fetch!(constants, name)
    %Env{env | constants: Map.put(constants, name, fun.(constant))}
  end
end
