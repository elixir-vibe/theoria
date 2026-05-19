defmodule Theoria.Equality.ChainTest do
  use ExUnit.Case, async: true

  alias Theoria.Equality.Chain
  alias Theoria.Equation.Identity
  alias Theoria.Prelude
  alias Theoria.Term

  test "realizes multi-step chains with explicit transitivity proofs" do
    {:ok, env} = Prelude.env()
    nat = Term.const(:Nat)
    zero = Term.const(:zero)

    chain =
      nat
      |> Chain.new(zero)
      |> Chain.step(zero, Term.refl(zero))
      |> Chain.step(zero, Term.refl(zero))

    assert {:ok, realized} = Chain.realize(env, chain, Identity.simp(:chain, :trans))

    assert %Term.EqRec{} = realized.proof
    assert realized.proof_strategy == :transitive
  end

  test "bridges missing defeq steps inside explicit transitive chains" do
    {:ok, env} = Prelude.env()
    nat = Term.const(:Nat)
    zero = Term.const(:zero)

    chain =
      nat
      |> Chain.new(zero)
      |> Chain.step(zero, Term.refl(zero))
      |> Chain.step(zero)
      |> Chain.step(zero, Term.refl(zero))

    assert {:ok, realized} = Chain.realize(env, chain, Identity.simp(:chain, :defeq_bridge))

    assert %Term.EqRec{} = realized.proof
    assert realized.proof_strategy == :transitive
  end

  test "marks defeq fallback when step proofs are missing" do
    {:ok, env} = Prelude.env()
    nat = Term.const(:Nat)
    zero = Term.const(:zero)
    chain = Chain.step(Chain.new(nat, zero), zero)

    assert {:ok, realized} = Chain.realize(env, chain, Identity.simp(:chain, :fallback))
    assert realized.proof_strategy == :fallback_defeq
  end
end
