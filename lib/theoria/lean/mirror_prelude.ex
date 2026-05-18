defmodule Theoria.Lean.MirrorPrelude do
  @moduledoc "Experimental/internal API for 0.2; subject to change before 0.3. Lean declarations that bridge Theoria primitives not rendered directly to Lean core."

  alias Theoria.Lean.Mirror.Inductive
  alias Theoria.Library.Vec

  @doc "Returns Lean source for the oracle mirror prelude."
  @spec source() :: String.t()
  def source do
    bridge = """
    set_option autoImplicit false
    set_option linter.unusedVariables false

    universe u v w

    namespace TheoriaOracle

    def tEqRec {A : Sort u} {x y : A} (motive : A -> Sort v) (base : motive x) (h : x = y) : motive y := by
      cases h
      exact base

    def tNatAdd : Nat -> Nat -> Nat
      | Nat.zero, n => n
      | Nat.succ m, n => Nat.succ (tNatAdd m n)

    """

    bridge <> Inductive.source!(Vec.inductive_spec()) <> indexed_matcher_source()
  end

  defp indexed_matcher_source do
    """
    axiom tVecValidationMatch
      (a : Type)
      (motive : forall (n : Nat), TVec a n -> Type)
      (n : Nat)
      (xs : TVec a n)
      (onVecNil : motive Nat.zero (@TVec.vec_nil a))
      (onVecCons : forall (head : a), forall (n : Nat), forall (tail : TVec a n), motive n tail -> motive (Nat.succ n) (@TVec.vec_cons a head n tail)) :
      motive n xs

    """
  end
end
