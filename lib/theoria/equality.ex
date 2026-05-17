defmodule Theoria.Equality do
  @moduledoc """
  Untrusted helpers for building equality transport terms.

  These helpers only construct core terms. Callers still need to pass the result
  through `Theoria.Kernel` before trusting it as a proof.
  """

  alias Theoria.Term

  @doc "Builds an equality-recursion transport term."
  @spec rewrite(Term.t(), Term.t(), Term.t(), Term.t()) :: Term.EqRec.t()
  def rewrite(type, motive, base, proof), do: Term.eq_rec(type, motive, base, proof)

  @doc "Builds a substitution proof from `base : motive left` and `proof : left = right`."
  @spec subst(Term.t(), Term.t(), Term.t(), Term.t()) :: Term.EqRec.t()
  def subst(type, motive, base, proof), do: rewrite(type, motive, base, proof)

  @doc "Builds nondependent equality transport by using a constant motive."
  @spec ndrec(Term.t(), Term.t(), Term.t(), Term.t()) :: Term.EqRec.t()
  def ndrec(type, codomain, base, proof) do
    rewrite(type, Term.lam(:_, type, Term.shift(codomain, 1)), base, proof)
  end

  @doc "Builds a symmetry proof from `proof : x = y`."
  @spec symm(Term.t(), Term.t(), Term.t(), Term.t()) :: Term.EqRec.t()
  def symm(type, left, _right, proof) do
    motive = Term.lam(:z, type, Term.eq(Term.shift(type, 1), Term.bvar(0), Term.shift(left, 1)))
    rewrite(type, motive, Term.refl(left), proof)
  end

  @doc "Builds a transitivity proof from `left = middle` and `middle = right`."
  @spec trans(Term.t(), Term.t(), Term.t(), Term.t(), Term.t(), Term.t()) :: Term.EqRec.t()
  def trans(type, left, _middle, _right, left_eq_middle, middle_eq_right) do
    motive = Term.lam(:z, type, Term.eq(Term.shift(type, 1), Term.shift(left, 1), Term.bvar(0)))
    rewrite(type, motive, left_eq_middle, middle_eq_right)
  end

  @doc "Builds congruence for a unary function."
  @spec congr(Term.t(), Term.t(), Term.t(), Term.t(), Term.t(), Term.t()) :: Term.EqRec.t()
  def congr(domain, codomain, fun, left, _right, proof) do
    motive =
      Term.lam(
        :z,
        domain,
        Term.eq(
          Term.shift(codomain, 1),
          Term.app(Term.shift(fun, 1), Term.shift(left, 1)),
          Term.app(Term.shift(fun, 1), Term.bvar(0))
        )
      )

    rewrite(domain, motive, Term.refl(Term.app(fun, left)), proof)
  end
end
