defmodule Theoria.Inductive.SpecBuilderTest do
  use ExUnit.Case, async: true

  alias Theoria.Env.Reduction
  alias Theoria.Inductive
  alias Theoria.Inductive.Spec

  import Theoria.Term

  test "builds specs with fluent helpers" do
    spec =
      :Nat
      |> Spec.new(sort(1), universe_params: [:u])
      |> Spec.constructor(:zero, const(:Nat))
      |> Spec.constructor(:succ, arrow(const(:Nat), const(:Nat)))
      |> Spec.recursor(:nat_rec, const(:Nat), %Reduction.NatRec{})

    assert spec.name == :Nat
    assert Enum.map(spec.constructors, & &1.name) == [:zero, :succ]
    assert Enum.map(spec.recursors, & &1.name) == [:nat_rec]
    assert Inductive.validate(spec) == :ok
  end
end
