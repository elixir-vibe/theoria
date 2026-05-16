defmodule Theoria.PrettyTest do
  use ExUnit.Case, async: true

  alias Theoria.Library.Logic
  alias Theoria.Library.Logic.Theorems

  import Theoria.Term

  test "inspects universes" do
    assert inspect(sort(0)) == "#Theoria<Prop>"
    assert inspect(sort(2)) == "#Theoria<Type 2>"
  end

  test "inspects variables with binder names" do
    type = forall(:p, sort(0), arrow(bvar(0), bvar(0)))

    assert inspect(type) == "#Theoria<∀ p : Prop, p → p>"
  end

  test "inspects lambdas" do
    proof = lam(:p, sort(0), lam(:hp, bvar(0), bvar(0)))

    assert inspect(proof) == "#Theoria<λ p : Prop, λ hp : p, hp>"
  end

  test "inspects equality and reflexivity" do
    assert inspect(eq(bvar(1), bvar(0), bvar(0))) == "#Theoria<#0 = #0>"
    assert inspect(refl(bvar(0))) == "#Theoria<refl #0>"
  end

  test "inspects checked theorems" do
    {:ok, env} = Logic.env()
    {:ok, theorem} = Theorems.identity_theorem(env)

    assert inspect(theorem) == "#Theoria<theorem identity : ∀ p : Prop, p → p>"
  end
end
