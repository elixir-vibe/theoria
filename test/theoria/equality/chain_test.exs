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
  end
end
