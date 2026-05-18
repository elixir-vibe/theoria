defmodule Theoria.Equation.Matcher.Indexed.RealizationTest do
  use ExUnit.Case, async: true

  alias Theoria.Equation.Identity
  alias Theoria.Equation.Matcher.Indexed.Realization
  alias Theoria.Kernel
  alias Theoria.Prelude
  alias Theoria.Validation.IndexedMatchers

  test "plans indexed matcher equation realization with refl proof terms" do
    {:ok, env} = Prelude.env()
    {:ok, package} = IndexedMatchers.check(env)

    assert {:ok, plan} = Realization.plan(package)
    assert Realization.realizable?(plan)
    assert Realization.blockers(plan) == []
    assert plan.matcher == :vec_validation_match

    assert Enum.map(plan.equations, & &1.lemma.identity) == [
             Identity.indexed_matcher_equation(:vec_validation_match, :vec_nil),
             Identity.indexed_matcher_equation(:vec_validation_match, :vec_cons)
           ]

    assert Enum.all?(plan.equations, &(&1.proof_strategy == :recursor_iota_refl))
    assert Enum.all?(plan.equations, & &1.realizable?)
    assert Enum.all?(plan.equations, &(&1.blockers == []))
    assert Enum.all?(plan.equations, &match?(%Theoria.Equation.Lemma{}, &1.lemma))
  end

  test "realizes indexed matcher equation theorems without installing them" do
    {:ok, env} = Prelude.env()
    {:ok, package} = IndexedMatchers.check(env)

    assert {:ok, theorem} =
             Realization.realize(
               package,
               Identity.indexed_matcher_equation(:vec_validation_match, :vec_cons)
             )

    assert theorem.identity == Identity.indexed_matcher_equation(:vec_validation_match, :vec_cons)
    assert :ok = Kernel.check(package.env, theorem.proof, theorem.type)

    assert {:ok, theorems} = Realization.realize_all(package)

    assert Enum.map(theorems, & &1.identity) == [
             Identity.indexed_matcher_equation(:vec_validation_match, :vec_nil),
             Identity.indexed_matcher_equation(:vec_validation_match, :vec_cons)
           ]
  end
end
