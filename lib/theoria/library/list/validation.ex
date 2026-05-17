defmodule Theoria.Library.List.Validation do
  @moduledoc "Validation metadata for `Theoria.Library.List`."

  alias Theoria.Library.{List, Nat}
  alias Theoria.Term

  alias Theoria.Validation.{
    DefeqCheck,
    InductiveCheck,
    Library,
    SmallTerms,
    Terms,
    TheoremModuleCheck
  }

  @doc "Returns validation checks owned by the List library."
  def checks do
    {:ok, nat_env} = Nat.env()

    Library.new(
      TheoremModuleCheck.new(:list, List.Theorems),
      defeq_checks(),
      [InductiveCheck.new(:list, :List, List.inductive_spec(), nat_env)]
    )
  end

  defp defeq_checks do
    nat = Term.const(:Nat)
    zero = Term.const(:zero)
    one = Term.app(Term.const(:succ), zero)
    nat_list = Term.app(Term.const(:List), nat)
    empty = Term.app(Term.const(:list_nil), nat)
    singleton = Term.const(:list_cons) |> Term.app(nat) |> Term.app(zero) |> Term.app(empty)
    list_succ_case = Terms.list_succ_case(nat_list)

    [
      DefeqCheck.new(
        :list,
        "list_length_nil",
        Term.const(:list_length) |> Term.app(nat) |> Term.app(empty),
        zero
      ),
      DefeqCheck.new(
        :list,
        "list_length_singleton",
        Term.const(:list_length) |> Term.app(nat) |> Term.app(singleton),
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
        |> Term.app(empty),
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
        |> Term.app(singleton),
        one
      )
    ] ++ SmallTerms.defeq_checks(:list)
  end
end
