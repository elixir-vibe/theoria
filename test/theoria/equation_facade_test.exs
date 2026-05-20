defmodule Theoria.EquationFacadeTest do
  use ExUnit.Case, async: true

  alias Theoria.Equation
  alias Theoria.Equation.Identity
  alias Theoria.Prelude

  test "facade exposes registry summaries, identities, and realization" do
    {:ok, env} = Prelude.env()

    summary = Equation.summary(env)
    assert Equation.Summary.definitions(summary) > 0
    assert Equation.Summary.theorems(summary) > 0
    assert {:ok, %{"theorems" => theorem_count}} = Jason.encode!(summary) |> Jason.decode()
    assert theorem_count == Equation.Summary.theorems(summary)

    assert {:ok, identities} = Equation.identities(env, :nat_add)
    assert Identity.equation(:nat_add, :succ) in identities
    assert {:ok, Identity.unfold(:nat_add)} == Equation.unfold_identity(env, :nat_add)
    assert Identity.unfold(:nat_add) in Equation.all_identities(env)

    assert {:ok, theorem} = Equation.realize(env, Identity.equation(:nat_add, :succ))
    assert theorem.name == Identity.equation(:nat_add, :succ)

    assert {:ok, theorems} = Equation.realize_all(env)
    assert length(theorems) == summary.theorems
  end
end
