defmodule Theoria.Inductive.CheckDeclarationsTest do
  use ExUnit.Case, async: true

  alias Theoria.Env
  alias Theoria.Inductive
  alias Theoria.Inductive.{Constructor, Spec}
  alias Theoria.Library.{Bool, List, Nat}

  import Theoria.Term

  test "checks Bool declaration plan against an empty environment" do
    assert Inductive.check_declarations(Env.new(), Bool.inductive_spec()) == :ok
  end

  test "checks Nat declaration plan against an empty environment" do
    assert Inductive.check_declarations(Env.new(), Nat.inductive_spec()) == :ok
  end

  test "checks List declaration plan over Nat declarations" do
    {:ok, env} = Nat.env()

    assert Inductive.check_declarations(env, List.inductive_spec()) == :ok
  end

  test "invalid declaration plans return validation errors" do
    spec = %Spec{
      name: :Bad,
      type: sort(1),
      constructors: [%Constructor{name: :bad, type: const(:Other)}]
    }

    assert {:error, error} = Inductive.check_declarations(Env.new(), spec)
    assert error.reason == :invalid_inductive
  end
end
