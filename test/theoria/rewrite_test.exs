defmodule Theoria.RewriteTest do
  use ExUnit.Case, async: true

  alias Theoria.Equation.Lemma
  alias Theoria.Prelude
  alias Theoria.Rewrite
  alias Theoria.Rewrite.{Database, Rule}
  alias Theoria.Term

  test "rewrites the first structural occurrence forward" do
    equality = Term.eq(Term.const(:Nat), Term.const(:zero), Term.const(:one))
    term = Term.app(Term.const(:succ), Term.const(:zero))

    assert Rewrite.once(term, equality) ==
             {:ok, Term.app(Term.const(:succ), Term.const(:one))}
  end

  test "rewrites backward" do
    equality = Term.eq(Term.const(:Nat), Term.const(:zero), Term.const(:one))
    term = Term.app(Term.const(:succ), Term.const(:one))

    assert Rewrite.once(term, equality, direction: Rewrite.direction!(:backward)) ==
             {:ok, Term.app(Term.const(:succ), Term.const(:zero))}
  end

  test "reports no replacement" do
    equality = Term.eq(Term.const(:Nat), Term.const(:zero), Term.const(:one))

    assert Rewrite.once(Term.const(:two), equality) == :not_found
  end

  test "database applies the first matching equation rule" do
    lemma = Lemma.new(:zero_to_one, Term.const(:zero), Term.const(:one))
    rule = Rule.from_lemma(lemma, Term.const(:Nat))
    database = Database.from_lemmas([lemma], Term.const(:Nat))
    term = Term.app(Term.const(:succ), Term.const(:zero))

    assert Database.once(database, term) ==
             {:ok, Term.app(Term.const(:succ), Term.const(:one)), rule}
  end

  test "database builds rules from generated environment equations" do
    {:ok, env} = Prelude.env()
    database = Database.from_env_equations(env)

    bool_false = Term.const(false)

    assert {:ok, ^bool_false, %Rule{name: :"bool_not.eq_true"}} =
             Database.once(database, Term.app(Term.const(:bool_not), Term.const(true)))

    singleton = list_cons(nat(), zero(), list_nil())

    append_nil =
      list_constant(:list_append)
      |> Term.app(nat())
      |> Term.app(list_nil())
      |> Term.app(singleton)

    assert {:ok, ^singleton, %Rule{name: :"list_append.eq_nil"}} =
             Database.once(database, append_nil)

    one = Term.app(Term.const(:succ), zero())
    add_zero = Term.const(:nat_add) |> Term.app(zero()) |> Term.app(one)

    assert {:ok, ^one, %Rule{name: :"nat_add.eq_zero"}} = Database.once(database, add_zero)
  end

  test "database can include generated matcher equations without indexed metadata" do
    {:ok, env} = Prelude.env()
    database = Database.from_env_all_equations(env)

    assert Enum.any?(database.rules, &(&1.name == :"bool_not.match_1.eq_true"))
    refute Enum.any?(database.rules, &(&1.name == :"vec_validation_match.eq_vec_nil"))

    assert {:ok, rewritten, %Rule{name: :"bool_not.match_1.eq_true"}} =
             Database.once(database, Term.app(Term.const(:bool_not), Term.const(true)))

    assert rewritten == Term.const(false)
  end

  defp nat, do: Term.const(:Nat)
  defp zero, do: Term.const(:zero)
  defp list_nil, do: Term.app(list_constant(:list_nil), nat())

  defp list_cons(type, head, tail) do
    list_constant(:list_cons)
    |> Term.app(type)
    |> Term.app(head)
    |> Term.app(tail)
  end

  defp list_constant(name), do: Term.const(name, [1])
end
