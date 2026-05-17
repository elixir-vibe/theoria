defmodule Theoria.Lean.MirrorPrelude do
  @moduledoc "Lean declarations that mirror Theoria's current oracle fragment."

  @doc "Returns Lean source for the oracle mirror prelude."
  @spec source() :: String.t()
  def source do
    """
    set_option autoImplicit false
    set_option linter.unusedVariables false

    universe u v w

    namespace TheoriaOracle

    def tEqRec {A : Sort u} {x y : A} (motive : A -> Sort v) (base : motive x) (h : x = y) : motive y := by
      cases h
      exact base

    inductive TBool : Type where
      | true_ : TBool
      | false_ : TBool

    namespace TBool

    def rec_.{r} (motive : Sort r) (onTrue : motive) (onFalse : motive) : TBool -> motive
      | true_ => onTrue
      | false_ => onFalse

    def ind_.{r} (motive : TBool -> Sort r) (onTrue : motive true_) (onFalse : motive false_) : (b : TBool) -> motive b
      | true_ => onTrue
      | false_ => onFalse

    def not_ : TBool -> TBool
      | true_ => false_
      | false_ => true_

    def and_ : TBool -> TBool -> TBool
      | true_, b => b
      | false_, _b => false_

    def or_ : TBool -> TBool -> TBool
      | true_, _b => true_
      | false_, b => b

    end TBool

    inductive TNat : Type where
      | zero : TNat
      | succ : TNat -> TNat

    namespace TNat

    def rec_.{r} (motive : Sort r) (zeroCase : motive) (succCase : TNat -> motive -> motive) : TNat -> motive
      | zero => zeroCase
      | succ n => succCase n (rec_ motive zeroCase succCase n)

    def ind_.{r} (motive : TNat -> Sort r) (zeroCase : motive zero) (succCase : (n : TNat) -> motive n -> motive (succ n)) : (n : TNat) -> motive n
      | zero => zeroCase
      | succ n => succCase n (ind_ motive zeroCase succCase n)

    def add : TNat -> TNat -> TNat
      | zero, n => n
      | succ m, n => succ (add m n)

    end TNat

    """
  end
end
