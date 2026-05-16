defmodule Theoria.Kernel.DeclarationKindTest do
  use ExUnit.Case, async: true

  alias Theoria.Env
  alias Theoria.Kernel
  alias Theoria.Library.Logic
  alias Theoria.Normalize

  import Theoria.Term

  test "definitions are reducible" do
    {:ok, env} = Kernel.add_definition(Env.new(), :P, sort(1), sort(0))

    assert {:ok, %{kind: :definition, reducible?: true}} = Env.fetch(env, :P)
    assert Normalize.normalize(env, const(:P)) == {:ok, sort(0)}
  end

  test "theorems are opaque" do
    {:ok, env} = Logic.env()
    {:ok, env} = Kernel.add_theorem(env, :truth, const(:True), const(:true_intro))

    assert {:ok, %{kind: :theorem, reducible?: false}} = Env.fetch(env, :truth)
    assert Normalize.normalize(env, const(:truth)) == {:ok, const(:truth)}
  end

  test "theorem proof is checked" do
    {:ok, env} = Logic.env()

    assert {:error, error} = Kernel.add_theorem(env, :bad, const(:True), const(:False))
    assert error.reason == :type_mismatch
  end

  test "environment validation preserves theorem declarations" do
    {:ok, env} = Logic.env()
    {:ok, env} = Kernel.add_theorem(env, :truth, const(:True), const(:true_intro))

    assert {:ok, checked_env} = Kernel.validate_env(env)
    assert {:ok, %{kind: :theorem, reducible?: false}} = Env.fetch(checked_env, :truth)
  end
end
