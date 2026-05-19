defmodule Theoria.Lean.MirrorPrelude do
  @moduledoc "Experimental before 1.0; the shape may change. Lean declarations that bridge Theoria primitives not rendered directly to Lean core."

  alias Theoria.Equation.Matcher.Spec, as: MatcherSpec
  alias Theoria.Lean.Encode
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
    {:ok, env} = Vec.env()
    info = Vec.indexed_matcher_info(:vec_validation_match)
    {:ok, spec} = MatcherSpec.indexed_from_info(info, env: env)

    """
    axiom #{Encode.constant(spec.name)} : #{Encode.term(spec.type)}

    """
  end
end
