defmodule Theoria.Validation.Terms do
  @moduledoc "Shared core terms used by Theoria validation checks."

  alias Theoria.Term

  @doc "Nat successor branch for non-dependent recursors returning Nat."
  @spec nat_succ_case() :: Term.t()
  def nat_succ_case do
    Term.lam(
      :_pred,
      Term.const(:Nat),
      Term.lam(:acc, Term.const(:Nat), Term.app(Term.const(:succ), Term.bvar(0)))
    )
  end

  @doc "List cons branch that increments a Nat accumulator."
  @spec list_succ_case(Term.t()) :: Term.t()
  def list_succ_case(list_type) do
    Term.lam(
      :_head,
      Term.const(:Nat),
      Term.lam(
        :_tail,
        list_type,
        Term.lam(:acc, Term.const(:Nat), Term.app(Term.const(:succ), Term.bvar(0)))
      )
    )
  end

  @doc "Vec motive returning Nat for each index/vector pair."
  @spec vec_nat_motive() :: Term.t()
  def vec_nat_motive do
    Term.lam(
      :n,
      Term.const(:Nat),
      Term.lam(
        :_xs,
        Term.const(:Vec) |> Term.app(Term.const(:Nat)) |> Term.app(Term.bvar(0)),
        Term.const(:Nat)
      )
    )
  end

  @doc "Vec cons branch that increments the induction hypothesis."
  @spec vec_succ_case() :: Term.t()
  def vec_succ_case do
    nearest = Term.bvar(0)

    Term.lam(
      :_head,
      Term.const(:Nat),
      Term.lam(
        :n,
        Term.const(:Nat),
        Term.lam(
          :_tail,
          Term.const(:Vec) |> Term.app(Term.const(:Nat)) |> Term.app(nearest),
          Term.lam(:ih, Term.const(:Nat), Term.app(Term.const(:succ), nearest))
        )
      )
    )
  end
end
