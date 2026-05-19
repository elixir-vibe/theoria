defmodule Theoria.Kernel.Corpus do
  @moduledoc "Curated kernel terms for production/reference differential checks."

  alias Theoria.Term

  @type infer_case :: {atom(), Term.t()}
  @type check_case :: {atom(), Term.t(), Term.t()}
  @type normalize_case :: {atom(), Term.t()}
  @type defeq_case :: {atom(), Term.t(), Term.t()}

  @doc "Returns reference-kernel inference cases."
  @spec infer_cases() :: [infer_case()]
  def infer_cases do
    bool = Term.const(:Bool)
    nat = Term.const(:Nat)
    zero = Term.const(:zero)
    bool_true = Term.const(true)
    type_zero = Term.sort(0)
    bvar_zero = Term.bvar(0)
    identity_type = Term.forall(:a, type_zero, Term.arrow(bvar_zero, bvar_zero))
    bool_refl = Term.refl(bool_true)

    [
      {:type_zero, type_zero},
      {:bool_constant, bool},
      {:nat_constant, nat},
      {:zero_constructor, zero},
      {:true_constructor, bool_true},
      {:succ_zero, Term.app(Term.const(:succ), zero)},
      {:bool_not_true, Term.app(Term.const(:bool_not), bool_true)},
      {:identity_type, identity_type},
      {:bool_equality_type, Term.eq(bool, bool_true, bool_true)},
      {:bool_refl, bool_refl},
      {:let_true, Term.let(:b, bool, bool_true, bvar_zero)},
      {:eq_rec_refl, eq_rec_refl(bool, bool_true, bool_refl)}
    ]
  end

  @doc "Returns reference-kernel checking cases."
  @spec check_cases() :: [check_case()]
  def check_cases do
    bool = Term.const(:Bool)
    nat = Term.const(:Nat)
    zero = Term.const(:zero)
    bool_true = Term.const(true)
    bool_false = Term.const(false)
    bvar_zero = Term.bvar(0)
    bool_refl = Term.refl(bool_true)
    bool_equality = Term.eq(bool, bool_true, bool_true)
    bool_identity = Term.lam(:b, bool, bvar_zero)
    bool_identity_type = Term.arrow(bool, bool)

    [
      {:zero_has_nat, zero, nat},
      {:true_has_bool, bool_true, bool},
      {:false_has_bool, bool_false, bool},
      {:bool_refl_checks, bool_refl, bool_equality},
      {:bool_identity_checks, bool_identity, bool_identity_type},
      {:let_true_checks, Term.let(:b, bool, bool_true, bvar_zero), bool},
      {:eq_rec_refl_checks, eq_rec_refl(bool, bool_true, bool_refl), bool_equality}
    ]
  end

  @doc "Returns normalization cases for production/reference comparison."
  @spec normalize_cases() :: [normalize_case()]
  def normalize_cases do
    bool = Term.const(:Bool)
    bool_true = Term.const(true)
    zero = Term.const(:zero)
    bvar_zero = Term.bvar(0)
    identity = Term.lam(:x, bool, bvar_zero)
    bool_refl = Term.refl(bool_true)

    [
      {:beta_identity_true, Term.app(identity, bool_true)},
      {:let_true, Term.let(:b, bool, bool_true, bvar_zero)},
      {:bool_not_true, Term.app(Term.const(:bool_not), bool_true)},
      {:succ_zero, Term.app(Term.const(:succ), zero)},
      {:eq_rec_refl, eq_rec_refl(bool, bool_true, bool_refl)}
    ]
  end

  @doc "Returns defeq cases for production/reference comparison."
  @spec defeq_cases() :: [defeq_case()]
  def defeq_cases do
    bool = Term.const(:Bool)
    bool_true = Term.const(true)
    bool_false = Term.const(false)
    bvar_zero = Term.bvar(0)
    identity = Term.lam(:x, bool, bvar_zero)

    [
      {:beta_identity_true, Term.app(identity, bool_true), bool_true},
      {:let_true, Term.let(:b, bool, bool_true, bvar_zero), bool_true},
      {:bool_not_true, Term.app(Term.const(:bool_not), bool_true), bool_false}
    ]
  end

  defp eq_rec_refl(type, value, proof) do
    motive = Term.lam(:z, type, Term.eq(Term.shift(type, 1), Term.bvar(0), Term.bvar(0)))
    Term.eq_rec(type, motive, Term.refl(value), proof)
  end
end
