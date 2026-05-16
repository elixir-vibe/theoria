defmodule Theoria.Inductive.InstallTest do
  use ExUnit.Case, async: true

  alias Theoria.Env
  alias Theoria.Inductive
  alias Theoria.Inductive.{Constructor, Spec}
  alias Theoria.Library.{Bool, List, Nat}

  import Theoria.Term

  test "installs Bool inductive declarations" do
    assert {:ok, env} = Inductive.install(Env.new(), Bool.inductive_spec())
    assert Inductive.verify_env(env, Bool.inductive_spec()) == :ok
  end

  test "installs Nat inductive declarations" do
    assert {:ok, env} = Inductive.install(Env.new(), Nat.inductive_spec())
    assert Inductive.verify_env(env, Nat.inductive_spec()) == :ok
  end

  test "installs List inductive declarations over Nat environment" do
    {:ok, env} = Nat.env()

    assert {:ok, env} = Inductive.install(env, List.inductive_spec())
    assert Inductive.verify_env(env, List.inductive_spec()) == :ok
  end

  test "fails when installing duplicate declarations" do
    assert {:ok, env} = Inductive.install(Env.new(), Bool.inductive_spec())
    assert {:error, error} = Inductive.install(env, Bool.inductive_spec())

    assert error.reason == :duplicate_declaration
    assert error.details == [name: :Bool]
  end

  test "invalid specs return validation errors" do
    spec = %Spec{
      name: :Bad,
      type: sort(1),
      constructors: [%Constructor{name: :bad, type: const(:Other)}]
    }

    assert {:error, error} = Inductive.install(Env.new(), spec)
    assert error.reason == :invalid_inductive
  end
end
