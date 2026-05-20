defmodule Theoria.ObligationTest do
  use ExUnit.Case, async: true

  alias Theoria.Certificate
  alias Theoria.Obligation
  alias Theoria.Term

  test "checks an obligation with a kernel-accepted proof" do
    goal = Term.eq(Term.sort(1), Term.sort(0), Term.sort(0))
    proof = Term.refl(Term.sort(0))
    obligation = Obligation.new(:sort_refl, goal, proof: proof, source: %{tool: :test})

    assert {:ok, certificate} = Obligation.check(Theoria.new_env(), obligation)
    assert Certificate.checked?(certificate)
    assert Certificate.status(certificate) == :checked
    assert Certificate.obligation(certificate) == obligation
    assert Certificate.checked_at(certificate)
    assert {:ok, replayed} = Certificate.replay(Theoria.new_env(), certificate)
    assert Certificate.checked?(replayed)
  end

  test "returns failed certificate for kernel-rejected proof" do
    goal = Term.eq(Term.sort(1), Term.sort(0), Term.sort(0))
    bad_proof = Term.sort(0)
    obligation = Obligation.new(:bad_sort_refl, goal, proof: bad_proof)

    assert {:error, certificate} = Obligation.check(Theoria.new_env(), obligation)
    assert Certificate.status(certificate) == :failed
    assert Certificate.reason(certificate)
  end

  test "returns unchecked certificate when proof is missing" do
    goal = Term.eq(Term.sort(1), Term.sort(0), Term.sort(0))
    obligation = Obligation.new(:missing_proof, goal)

    assert {:error, certificate} = Obligation.check(Theoria.new_env(), obligation)
    assert Certificate.status(certificate) == :unchecked
    assert Certificate.reason(certificate) == :missing_proof
    refute Certificate.checked_at(certificate)
  end

  test "accessors expose obligation metadata" do
    goal = Term.sort(0)

    obligation =
      Obligation.new(:metadata_claim, goal,
        id: "claim-1",
        assumptions: [:a],
        witness: %{path: [:x, :y]},
        source: %{tool: :reach},
        metadata: %{severity: :info}
      )

    assert Obligation.id(obligation) == "claim-1"
    assert Obligation.kind(obligation) == :metadata_claim
    assert Obligation.goal(obligation) == goal
    assert Obligation.proof(obligation) == nil
    assert Obligation.assumptions(obligation) == [:a]
    assert Obligation.witness(obligation) == %{path: [:x, :y]}
    assert Obligation.source(obligation) == %{tool: :reach}
    assert Obligation.metadata(obligation) == %{severity: :info}
  end
end
