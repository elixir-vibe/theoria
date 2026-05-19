defmodule Theoria.Kernel.Corpus do
  @moduledoc "Curated kernel terms for production/reference differential checks."

  alias Theoria.Term

  @type infer_case :: {atom(), Term.t()}
  @type check_case :: {atom(), Term.t(), Term.t()}

  @doc "Returns reference-kernel inference cases that avoid unsupported constructs."
  @spec infer_cases() :: [infer_case()]
  def infer_cases do
    bool = Term.const(:Bool)
    nat = Term.const(:Nat)
    zero = Term.const(:zero)
    bool_true = Term.const(true)
    type_zero = Term.sort(0)
    identity_type = Term.forall(:a, type_zero, Term.arrow(Term.bvar(0), Term.bvar(0)))

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
      {:bool_refl, Term.refl(bool_true)}
    ]
  end

  @doc "Returns reference-kernel checking cases that avoid unsupported constructs."
  @spec check_cases() :: [check_case()]
  def check_cases do
    bool = Term.const(:Bool)
    nat = Term.const(:Nat)
    zero = Term.const(:zero)
    bool_true = Term.const(true)
    bool_false = Term.const(false)
    bool_identity = Term.lam(:b, bool, Term.bvar(0))
    bool_identity_type = Term.arrow(bool, bool)

    [
      {:zero_has_nat, zero, nat},
      {:true_has_bool, bool_true, bool},
      {:false_has_bool, bool_false, bool},
      {:bool_refl_checks, Term.refl(bool_true), Term.eq(bool, bool_true, bool_true)},
      {:bool_identity_checks, bool_identity, bool_identity_type}
    ]
  end
end
