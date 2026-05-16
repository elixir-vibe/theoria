defmodule Theoria.Kernel.AxiomTest do
  use ExUnit.Case, async: true

  alias Theoria.Env
  alias Theoria.Kernel
  alias Theoria.Library.Logic

  import Theoria.Term

  test "adds axiom declarations" do
    {:ok, env} = Kernel.add_axiom(Env.new(), :assumption, sort(0))

    assert {:ok, %{kind: :axiom, reducible?: false, value: nil}} = Env.fetch(env, :assumption)
  end

  test "axiom type must be a sort" do
    env = Env.new() |> Env.put_constant(:proof, const(:Missing))
    assert {:error, error} = Kernel.add_axiom(env, :bad_axiom, const(:proof))

    assert error.reason == :expected_sort
  end

  test "reports direct axiom dependencies" do
    {:ok, env} = Logic.env()
    {:ok, env} = Kernel.add_axiom(env, :assumed_truth, const(:True))
    {:ok, env} = Kernel.add_theorem(env, :uses_axiom, const(:True), const(:assumed_truth))

    assert Kernel.axioms(env, :uses_axiom) == {:ok, MapSet.new([:assumed_truth])}
  end

  test "reports transitive axiom dependencies through theorem declarations" do
    {:ok, env} = Logic.env()
    {:ok, env} = Kernel.add_axiom(env, :assumed_truth, const(:True))
    {:ok, env} = Kernel.add_theorem(env, :first, const(:True), const(:assumed_truth))
    {:ok, env} = Kernel.add_theorem(env, :second, const(:True), const(:first))

    assert Kernel.axioms(env, :second) == {:ok, MapSet.new([:assumed_truth])}
  end

  test "theorems without axiom dependencies report empty set" do
    {:ok, env} = Logic.env()
    {:ok, env} = Kernel.add_theorem(env, :truth, const(:True), const(:true_intro))

    assert Kernel.axioms(env, :truth) == {:ok, MapSet.new()}
  end

  test "environment validation preserves axiom declarations" do
    {:ok, env} = Kernel.add_axiom(Env.new(), :assumption, sort(0))

    assert {:ok, checked_env} = Kernel.validate_env(env)
    assert {:ok, %{kind: :axiom, reducible?: false}} = Env.fetch(checked_env, :assumption)
  end
end
