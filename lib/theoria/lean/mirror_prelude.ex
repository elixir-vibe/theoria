defmodule Theoria.Lean.MirrorPrelude do
  @moduledoc "Lean declarations that mirror Theoria's current oracle fragment."

  @doc "Returns Lean source for the oracle mirror prelude."
  @spec source() :: String.t()
  def source do
    """
    set_option autoImplicit false

    universe u v w

    namespace TheoriaOracle

    def tEqRec {A : Sort u} {x y : A} (motive : A -> Sort v) (base : motive x) (h : x = y) : motive y := by
      cases h
      exact base

    inductive TBool : Type where
      | true_ : TBool
      | false_ : TBool

    inductive TNat : Type where
      | zero : TNat
      | succ : TNat -> TNat

    namespace TNat

    def add : TNat -> TNat -> TNat
      | zero, n => n
      | succ m, n => succ (add m n)

    end TNat

    """
  end
end
