defmodule Theoria.TermTest do
  use ExUnit.Case, async: true

  import Theoria.Term

  test "substitution avoids capture under lambdas" do
    body = lam(:x, sort(0), bvar(1))

    assert subst_top(body, bvar(0)) == lam(:x, sort(0), bvar(1))
  end

  test "arrow lifts the codomain under the binder" do
    assert arrow(bvar(0), bvar(0)) == forall(:_, bvar(0), bvar(1))
  end

  test "shift respects binder cutoff" do
    term = lam(:x, sort(0), app(bvar(1), bvar(0)))

    assert shift(term, 1) == lam(:x, sort(0), app(bvar(2), bvar(0)))
  end

  test "substitution traverses equality and reflexivity" do
    body = eq(bvar(0), refl(bvar(0)), bvar(0))

    assert subst(body, 0, bvar(2)) == eq(bvar(2), refl(bvar(2)), bvar(2))
  end

  test "substitution traverses equality recursors" do
    body = eq_rec(bvar(0), bvar(0), bvar(0), bvar(0))

    assert subst(body, 0, bvar(2)) == eq_rec(bvar(2), bvar(2), bvar(2), bvar(2))
  end

  test "well scoped checks bound variable depth" do
    assert well_scoped?(forall(:x, sort(0), bvar(0)))
    refute well_scoped?(forall(:x, sort(0), bvar(1)))
    assert well_scoped?(bvar(1), 2)
    refute well_scoped?(bvar(2), 2)
  end
end
