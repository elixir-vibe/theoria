defmodule Theoria.Library.Vec.Validation do
  @moduledoc "Validation metadata for `Theoria.Library.Vec`."

  alias Theoria.Library.{Nat, Vec}
  alias Theoria.Term

  alias Theoria.Validation.{
    DefeqCheck,
    InductiveCheck,
    Library,
    SmallTerms,
    Terms,
    TheoremModuleCheck
  }

  @doc "Returns validation checks owned by the Vec library."
  def checks do
    {:ok, nat_env} = Nat.env()

    Library.new(
      TheoremModuleCheck.new(:vec, Vec.Theorems),
      defeq_checks(),
      [InductiveCheck.new(:vec, :Vec, Vec.inductive_spec(), nat_env)]
    )
  end

  defp defeq_checks do
    nat = Term.const(:Nat)
    zero = Term.const(:zero)
    one = Term.app(Term.const(:succ), zero)
    empty = Term.app(Term.const(:vec_nil), nat)

    singleton =
      Term.const(:vec_cons)
      |> Term.app(nat)
      |> Term.app(zero)
      |> Term.app(zero)
      |> Term.app(empty)

    [
      DefeqCheck.new(:vec, "vec_ind_nil", vec_ind(zero, empty), zero),
      DefeqCheck.new(:vec, "vec_ind_cons", vec_ind(one, singleton), one)
    ] ++ SmallTerms.defeq_checks(:vec)
  end

  defp vec_ind(index, vector) do
    Term.const(:vec_ind)
    |> Term.app(Term.const(:Nat))
    |> Term.app(Terms.vec_nat_motive())
    |> Term.app(Term.const(:zero))
    |> Term.app(Terms.vec_succ_case())
    |> Term.app(index)
    |> Term.app(vector)
  end
end
