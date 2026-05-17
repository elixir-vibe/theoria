defmodule Theoria.Library.Equality.Validation do
  @moduledoc "Validation metadata for `Theoria.Library.Equality`."

  alias Theoria.Library.Equality
  alias Theoria.Term
  alias Theoria.Validation.{DefeqCheck, Library, TheoremModuleCheck}

  @doc "Returns validation checks owned by the equality library."
  def checks do
    Library.new(TheoremModuleCheck.new(:equality, Equality.Theorems), defeq_checks())
  end

  defp defeq_checks do
    nat = Term.const(:Nat)
    zero = Term.const(:zero)
    one = Term.app(Term.const(:succ), zero)
    id = Term.lam(:n, nat, Term.bvar(0))
    refl_zero = Term.refl(zero)
    refl_one = Term.refl(one)

    [
      DefeqCheck.new(
        :equality,
        "eq_rec_refl",
        Term.eq_rec(nat, Term.lam(:n, nat, nat), zero, refl_zero),
        zero
      ),
      DefeqCheck.new(
        :equality,
        "eq_ndrec_refl",
        Theoria.Equality.ndrec(nat, nat, zero, refl_zero),
        zero
      ),
      DefeqCheck.new(
        :equality,
        "eq_congr_refl",
        Theoria.Equality.congr(nat, nat, id, zero, zero, refl_zero),
        refl_zero
      ),
      DefeqCheck.new(
        :equality,
        "eq_symm_refl",
        Theoria.Equality.symm(nat, zero, zero, refl_zero),
        refl_zero
      ),
      DefeqCheck.new(
        :equality,
        "eq_trans_refl",
        Theoria.Equality.trans(nat, zero, zero, zero, refl_zero, refl_zero),
        refl_zero
      ),
      DefeqCheck.new(
        :equality,
        "eq_congr_succ_refl",
        Theoria.Equality.congr(nat, nat, Term.const(:succ), zero, zero, refl_zero),
        refl_one
      )
    ]
  end
end
