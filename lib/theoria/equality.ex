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
end
