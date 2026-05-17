defmodule Theoria.Library.Nat.Validation do
  @moduledoc "Validation metadata for `Theoria.Library.Nat`."

  alias Theoria.Env
  alias Theoria.Equation
  alias Theoria.Equation.{Clause, Lemma, Pattern}
  alias Theoria.Library.Nat
  alias Theoria.Term

  alias Theoria.Validation.{
    DefeqCheck,
    InductiveCheck,
    Library,
    SmallTerms,
    Terms,
    TheoremModuleCheck
  }

  @doc "Returns validation checks owned by the Nat library."
  def checks do
    Library.new(
      TheoremModuleCheck.new(:nat, Nat.Theorems),
      defeq_checks(),
      [InductiveCheck.new(:nat, :Nat, Nat.inductive_spec(), Env.new())]
    )
  end

  defp defeq_checks do
    nat = Term.const(:Nat)
    zero = Term.const(:zero)
    one = Term.app(Term.const(:succ), zero)
    two = Term.app(Term.const(:succ), one)

    add_clauses = [
      Clause.new([Pattern.constructor(:zero)], zero),
      Clause.new(
        [Pattern.constructor(:succ, [Pattern.var(:n)])],
        fn ctx -> Term.app(Term.const(:succ), ctx.ih) end
      )
    ]

    {:ok, compiled_succ} = Equation.compile_nat(nat, add_clauses, one)
    {:ok, compiled_add_two_zero} = Equation.compile_nat(nat, add_clauses, two)

    [
      Lemma.defeq_check(
        Lemma.new(:equation_nat_succ, compiled_succ, one),
        :nat
      ),
      Lemma.defeq_check(
        Lemma.new(:equation_nat_add_two_zero, compiled_add_two_zero, two),
        :nat
      ),
      DefeqCheck.new(
        :nat,
        "nat_rec_zero",
        Term.const(:nat_rec)
        |> Term.app(nat)
        |> Term.app(zero)
        |> Term.app(Terms.nat_succ_case())
        |> Term.app(zero),
        zero
      ),
      DefeqCheck.new(
        :nat,
        "nat_rec_succ",
        Term.const(:nat_rec)
        |> Term.app(nat)
        |> Term.app(zero)
        |> Term.app(Terms.nat_succ_case())
        |> Term.app(one),
        one
      ),
      DefeqCheck.new(
        :nat,
        "nat_add_one_zero",
        Term.const(:nat_add) |> Term.app(one) |> Term.app(zero),
        one
      ),
      DefeqCheck.new(
        :nat,
        "nat_add_two_zero",
        Term.const(:nat_add) |> Term.app(two) |> Term.app(zero),
        two
      )
    ] ++ SmallTerms.defeq_checks(:nat)
  end
end
