defmodule Theoria.PrettyTest do
  use ExUnit.Case, async: true

  alias Theoria.Kernel
  alias Theoria.Level
  alias Theoria.Library.Logic
  alias Theoria.Library.Logic.Theorems

  import Theoria.Term

  test "inspects universes" do
    assert inspect(sort(0)) == "#Theoria<Prop>"
    assert inspect(sort(2)) == "#Theoria<Type 2>"
    assert inspect(sort(Level.param(:u))) == "#Theoria<Sort u>"
    assert inspect(Level.param(:u)) == "#Theoria<level u>"
  end

  test "inspects universe-polymorphic constants" do
    assert inspect(const(:List, [1])) == "#Theoria<List.1>"
    assert inspect(const(:List, [Level.param(:u)])) == "#Theoria<List.u>"
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

  test "inspects trust reports" do
    {:ok, env} = Logic.env()
    {:ok, env} = Kernel.add_axiom(env, :assumed_truth, const(:True))
    {:ok, env} = Kernel.add_theorem(env, :truth, const(:True), const(:assumed_truth))
    {:ok, report} = Kernel.trust_report(env, :truth)

    assert inspect(report) ==
             "#Theoria<trust truth : theorem, axioms: assumed_truth, deps: True, assumed_truth>"
  end
end
