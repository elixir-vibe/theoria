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
end
