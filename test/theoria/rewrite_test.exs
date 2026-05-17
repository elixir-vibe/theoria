defmodule Theoria.RewriteTest do
  use ExUnit.Case, async: true

  alias Theoria.Equation.Lemma
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

    assert Rewrite.once(term, equality, direction: Rewrite.direction(:backward)) ==
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
end
