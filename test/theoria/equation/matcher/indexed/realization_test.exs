defmodule Theoria.Equation.Matcher.Indexed.RealizationTest do
  use ExUnit.Case, async: true

  alias Theoria.Equation.Matcher.Indexed.Realization
  alias Theoria.Prelude
  alias Theoria.Validation.IndexedMatchers

  test "plans indexed matcher equation realization without enabling proofs" do
    {:ok, env} = Prelude.env()
    {:ok, package} = IndexedMatchers.check(env)

    assert {:ok, plan} = Realization.plan(package)
    refute Realization.realizable?(plan)
    assert Realization.blockers(plan) == [:proof_term_generation_not_implemented]
    assert plan.matcher == :vec_validation_match

    assert Enum.map(plan.equations, & &1.name) == [
             :"vec_validation_match.eq_vec_nil",
             :"vec_validation_match.eq_vec_cons"
           ]

    assert Enum.all?(plan.equations, &(&1.proof_strategy == :recursor_iota_refl))
    assert Enum.all?(plan.equations, &(&1.realizable? == false))
    assert Enum.all?(plan.equations, &(&1.blockers == [:proof_term_generation_not_implemented]))
    assert Enum.all?(plan.equations, &match?(%Theoria.Equation.Lemma{}, &1.lemma))
  end
end
