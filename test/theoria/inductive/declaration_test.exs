defmodule Theoria.Inductive.DeclarationTest do
  use ExUnit.Case, async: true

  alias Theoria.Env.Reduction
  alias Theoria.Inductive
  alias Theoria.Inductive.{Constructor, Declaration, Spec}
  alias Theoria.Library.{Bool, List, Nat}

  import Theoria.Term

  test "generates Bool declaration plan" do
    assert {:ok, declarations} = Inductive.declarations(Bool.inductive_spec())

    assert Enum.map(declarations, & &1.name) == [:Bool, true, false, :bool_rec, :bool_ind]
    assert %Declaration{kind: :constant, universe_params: []} = hd(declarations)

    assert %Declaration{reduction: %Reduction.BoolRec{}} =
             Enum.find(declarations, &(&1.name == :bool_rec))

    assert %Declaration{reduction: %Reduction.BoolInd{}} =
             Enum.find(declarations, &(&1.name == :bool_ind))
  end

  test "generates Nat declaration plan" do
    assert {:ok, declarations} = Inductive.declarations(Nat.inductive_spec())

    assert Enum.map(declarations, & &1.name) == [:Nat, :zero, :succ, :nat_rec, :nat_ind]

    assert %Declaration{reduction: %Reduction.NatRec{}} =
             Enum.find(declarations, &(&1.name == :nat_rec))

    assert %Declaration{reduction: %Reduction.NatInd{}} =
             Enum.find(declarations, &(&1.name == :nat_ind))
  end

  test "generates List declaration plan" do
    assert {:ok, declarations} = Inductive.declarations(List.inductive_spec())

    assert Enum.map(declarations, & &1.name) == [
             :List,
             :list_nil,
             :list_cons,
             :list_rec,
             :list_ind
           ]

    assert %Declaration{universe_params: [:u]} = Enum.find(declarations, &(&1.name == :List))

    assert %Declaration{universe_params: [:u, :v]} =
             Enum.find(declarations, &(&1.name == :list_rec))

    assert %Declaration{reduction: %Reduction.ListRec{}} =
             Enum.find(declarations, &(&1.name == :list_rec))

    assert %Declaration{reduction: %Reduction.ListInd{}} =
             Enum.find(declarations, &(&1.name == :list_ind))
  end

  test "invalid specs return validation errors" do
    spec = %Spec{
      name: :Bad,
      type: sort(1),
      constructors: [%Constructor{name: :bad, type: const(:Other)}]
    }

    assert {:error, error} = Inductive.declarations(spec)
    assert error.reason == :invalid_inductive
  end
end
