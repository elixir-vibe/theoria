defmodule Theoria.SpecTest do
  use ExUnit.Case, async: true

  alias Theoria.Certificate
  alias Theoria.Obligation
  alias Theoria.Spec
  alias Theoria.Spec.Finite
  alias Theoria.Term

  test "builds obligations from valid structural claims" do
    claim = Finite.subset_claim([:a], [:a, :b])
    goal = Term.eq(Term.sort(1), Term.sort(0), Term.sort(0))
    proof = Term.refl(Term.sort(0))

    assert {:ok, obligation} = Spec.obligation(claim, goal, proof: proof, source: %{tool: :test})
    assert Obligation.kind(obligation) == :finite_subset
    assert Obligation.witness(obligation) == claim
    assert Obligation.source(obligation) == %{tool: :test}
    assert Obligation.metadata(obligation) == %{claim_kind: :finite_subset}
  end

  test "rejects obligations from invalid structural claims" do
    claim = Finite.no_new_claim([:a], [:a, :b])
    goal = Term.eq(Term.sort(1), Term.sort(0), Term.sort(0))

    assert {:error, {:invalid_spec_claim, :finite_no_new, {:added, [:b]}}} =
             Spec.obligation(claim, goal)
  end

  test "checks obligations generated from valid claims" do
    claim = Finite.subset_claim([:a], [:a, :b])
    goal = Term.eq(Term.sort(1), Term.sort(0), Term.sort(0))
    proof = Term.refl(Term.sort(0))

    assert {:ok, certificate} = Spec.check_claim(Theoria.new_env(), claim, goal, proof: proof)
    assert Certificate.checked?(certificate)
  end

  test "reports structural claim validity" do
    valid = Finite.subset_claim([:a], [:a])
    invalid = Finite.subset_claim([:b], [:a])

    assert Spec.valid?(valid)
    refute Spec.valid?(invalid)
    refute Spec.all_valid?([valid, invalid])
    assert Spec.report([valid, invalid]).invalid == 1
  end
end
