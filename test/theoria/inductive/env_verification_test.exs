defmodule Theoria.Inductive.EnvVerificationTest do
  use ExUnit.Case, async: true

  alias Theoria.Env
  alias Theoria.Env.Constant
  alias Theoria.Inductive
  alias Theoria.Library.{Bool, List, Nat}

  import Theoria.Term

  test "verifies Bool spec against Bool environment" do
    {:ok, env} = Bool.env()

    assert Inductive.verify_env(env, Bool.inductive_spec()) == :ok
  end

  test "verifies Nat spec against Nat environment" do
    {:ok, env} = Nat.env()

    assert Inductive.verify_env(env, Nat.inductive_spec()) == :ok
  end

  test "verifies List spec against List environment" do
    {:ok, env} = List.env()

    assert Inductive.verify_env(env, List.inductive_spec()) == :ok
  end

  test "reports missing declarations" do
    {:ok, env} = Nat.env()
    env = remove_declaration(env, :nat_ind)

    assert {:error, error} = Inductive.verify_env(env, Nat.inductive_spec())
    assert error.reason == :inductive_env_mismatch
    assert error.details == [name: :nat_ind, problem: :missing]
  end

  test "reports type mismatches" do
    {:ok, env} = Nat.env()
    env = put_constant(env, :succ, %Constant{type: const(:Nat)})

    assert {:error, error} = Inductive.verify_env(env, Nat.inductive_spec())
    assert error.details == [name: :succ, problem: :type]
  end

  test "reports universe parameter mismatches" do
    {:ok, env} = Nat.env()

    env =
      put_constant(env, :nat_rec, fn %Constant{} = constant ->
        %Constant{constant | universe_params: [:v]}
      end)

    assert {:error, error} = Inductive.verify_env(env, Nat.inductive_spec())
    assert error.details == [name: :nat_rec, problem: :universe_params]
  end

  test "reports reduction metadata mismatches" do
    {:ok, env} = Nat.env()

    env =
      put_constant(env, :nat_rec, fn %Constant{} = constant ->
        %Constant{constant | reduction: nil}
      end)

    assert {:error, error} = Inductive.verify_env(env, Nat.inductive_spec())
    assert error.details == [name: :nat_rec, problem: :reduction]
  end

  defp remove_declaration(%Env{constants: constants, declarations: declarations} = env, name) do
    %Env{
      env
      | constants: Map.delete(constants, name),
        declarations: Enum.reject(declarations, &(&1 == name))
    }
  end

  defp put_constant(%Env{constants: constants} = env, name, fun) when is_function(fun, 1) do
    %Constant{} = constant = Map.fetch!(constants, name)
    %Env{env | constants: Map.put(constants, name, fun.(constant))}
  end

  defp put_constant(%Env{constants: constants} = env, name, %Constant{} = constant) do
    %Env{env | constants: Map.put(constants, name, constant)}
  end
end
