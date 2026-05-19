defmodule Theoria.Kernel.ReferenceEqRecTest do
  use ExUnit.Case, async: true

  alias Theoria.Kernel
  alias Theoria.Kernel.Reference
  alias Theoria.Kernel.Reference.Normalize, as: ReferenceNormalize
  alias Theoria.Normalize
  alias Theoria.Prelude
  alias Theoria.Term

  test "production and reference normalize EqRec over Refl to the base" do
    {:ok, env} = Prelude.env()
    term = eq_rec_zero()

    assert Normalize.normalize(env, term) == {:ok, Term.const(:zero)}
    assert ReferenceNormalize.normalize(env, term) == {:ok, Term.const(:zero)}
  end

  test "production and reference agree on nested EqRec" do
    {:ok, env} = Prelude.env()
    term = nested_eq_rec_zero()

    assert Kernel.infer(env, term) == Reference.infer(env, term)
    assert Normalize.normalize(env, term) == ReferenceNormalize.normalize(env, term)
  end

  test "production and reference agree on EqRec inside equality proofs" do
    {:ok, env} = Prelude.env()
    nat = Term.const(:Nat)
    term = eq_rec_zero()
    equality = Term.eq(nat, term, Term.const(:zero))
    proof = Term.refl(term)

    assert Kernel.check(env, proof, equality) == Reference.check(env, proof, equality)
  end

  defp eq_rec_zero do
    nat = Term.const(:Nat)
    zero = Term.const(:zero)
    motive = Term.lam(:n, nat, Term.shift(nat, 1))
    Term.eq_rec(nat, motive, zero, Term.refl(zero))
  end

  defp nested_eq_rec_zero do
    nat = Term.const(:Nat)
    zero = Term.const(:zero)
    motive = Term.lam(:n, nat, Term.shift(nat, 1))
    Term.eq_rec(nat, motive, eq_rec_zero(), Term.refl(zero))
  end
end
