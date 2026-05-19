defmodule Theoria.Kernel.Generator do
  @moduledoc """
  Experimental typed term generators for kernel/reference differential assurance.

  The generators return `%Theoria.Kernel.GeneratedTerm{}` values that pair a
  closed term with its expected type and environment.
  """

  import StreamData

  alias Theoria.Kernel.GeneratedTerm
  alias Theoria.Prelude
  alias Theoria.Term

  @spec small_terms(keyword()) :: StreamData.t(GeneratedTerm.t())
  def small_terms(opts \\ []) do
    size = Keyword.get(opts, :size, 3)
    {:ok, env} = Prelude.env()
    bool = Term.const(:Bool)
    nat = Term.const(:Nat)

    one_of([
      map(bool_terms(size), &GeneratedTerm.new(env, &1, bool)),
      map(nat_terms(size), &GeneratedTerm.new(env, &1, nat)),
      map(nat_terms(size), fn term ->
        equality = Term.eq(nat, term, term)
        GeneratedTerm.new(env, Term.refl(term), equality)
      end),
      map(nat_terms(size), fn term ->
        motive = Term.lam(:n, nat, Term.shift(nat, 1))
        GeneratedTerm.new(env, Term.eq_rec(nat, motive, term, Term.refl(term)), nat)
      end),
      map(bool_terms(size), fn term ->
        GeneratedTerm.new(env, Term.lam(:x, bool, Term.shift(term, 1)), Term.arrow(bool, bool))
      end)
    ])
  end

  @spec bool_terms(non_neg_integer()) :: StreamData.t(Term.t())
  def bool_terms(0), do: member_of([Term.const(true), Term.const(false)])

  def bool_terms(size) when size > 0 do
    smaller = bool_terms(size - 1)

    one_of([
      bool_terms(0),
      map(smaller, &Term.app(Term.const(:bool_not), &1)),
      map(tuple({smaller, smaller}), fn {left, right} ->
        Term.app(Term.app(Term.const(:bool_and), left), right)
      end),
      map(tuple({smaller, smaller}), fn {left, right} ->
        Term.app(Term.app(Term.const(:bool_or), left), right)
      end)
    ])
  end

  @spec nat_terms(non_neg_integer()) :: StreamData.t(Term.t())
  def nat_terms(0),
    do: member_of([Term.const(:zero), Term.app(Term.const(:succ), Term.const(:zero))])

  def nat_terms(size) when size > 0 do
    smaller = nat_terms(size - 1)

    one_of([
      nat_terms(0),
      map(smaller, &Term.app(Term.const(:succ), &1)),
      map(tuple({smaller, smaller}), fn {left, right} ->
        Term.app(Term.app(Term.const(:nat_add), left), right)
      end)
    ])
  end
end
