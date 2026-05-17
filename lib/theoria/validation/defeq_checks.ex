defmodule Theoria.Validation.DefeqChecks do
  @moduledoc "Theoria-owned definitional-equality checks used by local and Lean validation."

  alias Theoria.Term
  alias Theoria.Validation.DefeqCheck
  alias Theoria.Validation.SmallTerms
  alias Theoria.Validation.Terms

  @doc "Returns the built-in definitional-equality checks."
  @spec all() :: [DefeqCheck.t()]
  def all do
    explicit_checks() ++ SmallTerms.defeq_checks()
  end

  defp explicit_checks do
    bool = Term.const(:Bool)
    nat = Term.const(:Nat)
    type = Term.sort(1)
    var = Term.bvar(0)
    bool_true = Term.const(true)
    bool_false = Term.const(false)
    zero = Term.const(:zero)
    succ = Term.const(:succ)
    one = Term.app(succ, zero)
    two = Term.app(succ, one)
    nat_list = Term.app(Term.const(:List), nat)
    list_succ_case = Terms.list_succ_case(nat_list)
    nil_nat = Term.app(Term.const(:list_nil), nat)
    vec_nil_nat = Term.app(Term.const(:vec_nil), nat)

    vec_singleton_zero =
      Term.const(:vec_cons)
      |> Term.app(nat)
      |> Term.app(zero)
      |> Term.app(zero)
      |> Term.app(vec_nil_nat)

    singleton_zero =
      Term.const(:list_cons) |> Term.app(nat) |> Term.app(zero) |> Term.app(nil_nat)

    [
      DefeqCheck.new(:defeq, "beta_identity", Term.app(Term.lam(:x, type, var), nat), nat),
      DefeqCheck.new(:defeq, "zeta_identity", Term.let(:x, type, nat, var), nat),
      DefeqCheck.new(
        :bool,
        "bool_not_true",
        Term.app(Term.const(:bool_not), bool_true),
        bool_false
      ),
      DefeqCheck.new(
        :bool,
        "bool_not_false",
        Term.app(Term.const(:bool_not), bool_false),
        bool_true
      ),
      DefeqCheck.new(
        :bool,
        "bool_and_true_false",
        Term.const(:bool_and) |> Term.app(bool_true) |> Term.app(bool_false),
        bool_false
      ),
      DefeqCheck.new(
        :bool,
        "bool_or_false_true",
        Term.const(:bool_or) |> Term.app(bool_false) |> Term.app(bool_true),
        bool_true
      ),
      DefeqCheck.new(
        :bool,
        "bool_rec_true",
        Term.const(:bool_rec)
        |> Term.app(bool)
        |> Term.app(bool_true)
        |> Term.app(bool_false)
        |> Term.app(bool_true),
        bool_true
      ),
      DefeqCheck.new(
        :bool,
        "bool_rec_false",
        Term.const(:bool_rec)
        |> Term.app(bool)
        |> Term.app(bool_true)
        |> Term.app(bool_false)
        |> Term.app(bool_false),
        bool_false
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
      ),
      DefeqCheck.new(
        :list,
        "list_length_nil",
        Term.const(:list_length) |> Term.app(nat) |> Term.app(nil_nat),
        zero
      ),
      DefeqCheck.new(
        :list,
        "list_length_singleton",
        Term.const(:list_length) |> Term.app(nat) |> Term.app(singleton_zero),
        one
      ),
      DefeqCheck.new(
        :list,
        "list_rec_nil",
        Term.const(:list_rec)
        |> Term.app(nat)
        |> Term.app(nat)
        |> Term.app(zero)
        |> Term.app(list_succ_case)
        |> Term.app(nil_nat),
        zero
      ),
      DefeqCheck.new(
        :list,
        "list_rec_cons",
        Term.const(:list_rec)
        |> Term.app(nat)
        |> Term.app(nat)
        |> Term.app(zero)
        |> Term.app(list_succ_case)
        |> Term.app(singleton_zero),
        one
      ),
      DefeqCheck.new(:vec, "vec_ind_nil", vec_ind(zero, vec_nil_nat), zero),
      DefeqCheck.new(:vec, "vec_ind_cons", vec_ind(one, vec_singleton_zero), one)
    ]
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
