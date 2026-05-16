defmodule Theoria.Elaborator.ShadowingTest do
  use ExUnit.Case, async: true

  alias Theoria.Elaborator
  alias Theoria.Syntax, as: S

  import Theoria.Term

  test "lambda shadowing resolves to the innermost binder" do
    term =
      S.lam(:x, S.sort(0), S.lam(:x, S.sort(0), S.var(:x)))

    assert Elaborator.elaborate(term) == {:ok, lam(:x, sort(0), lam(:x, sort(0), bvar(0)))}
  end

  test "inner lambda body can reference an outer binder" do
    term =
      S.lam(:x, S.sort(0), S.lam(:y, S.sort(0), S.var(:x)))

    assert Elaborator.elaborate(term) == {:ok, lam(:x, sort(0), lam(:y, sort(0), bvar(1)))}
  end

  test "forall shadowing resolves to the innermost binder" do
    term =
      S.forall(:x, S.sort(0), S.forall(:x, S.sort(0), S.var(:x)))

    assert Elaborator.elaborate(term) == {:ok, forall(:x, sort(0), forall(:x, sort(0), bvar(0)))}
  end

  test "dependent domains can reference outer binders" do
    term =
      S.forall(:a, S.sort(1), S.forall(:x, S.var(:a), S.var(:a)))

    assert Elaborator.elaborate(term) == {:ok, forall(:a, sort(1), forall(:x, bvar(0), bvar(1)))}
  end

  test "unbound name errors include the visible context" do
    term =
      S.forall(:x, S.sort(0), S.var(:missing))

    assert {:error, error} = Elaborator.elaborate(term)
    assert error.reason == :unbound_name
    assert error.details == [name: :missing, context: [:x]]
  end

  test "explicit context resolves nearest matching name first" do
    assert Elaborator.elaborate(S.var(:x), [:x, :y, :x]) == {:ok, bvar(0)}
  end
end
