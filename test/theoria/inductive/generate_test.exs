defmodule Theoria.Inductive.GenerateTest do
  use ExUnit.Case, async: true

  alias Theoria.Env.Reduction
  alias Theoria.Inductive.Generate
  alias Theoria.Inductive.Spec
  alias Theoria.Library.{Bool, List, Nat}

  test "generates Bool eliminators from constructors" do
    spec =
      :Bool
      |> Spec.new(Bool.type(), universe_params: [:u])
      |> Spec.constructor(true, Theoria.Term.const(:Bool))
      |> Spec.constructor(false, Theoria.Term.const(:Bool))

    assert [rec, ind] = Generate.bool_eliminators(spec)
    assert rec.name == :bool_rec
    assert rec.reduction == %Reduction.BoolRec{}
    assert ind.name == :bool_ind
    assert ind.reduction == %Reduction.BoolInd{}
  end

  test "generates Nat eliminators from constructors" do
    spec = without_recursors(Nat.inductive_spec())

    assert [rec, ind] = Generate.nat_eliminators(spec)
    assert rec.name == :nat_rec
    assert rec.reduction == %Reduction.NatRec{}
    assert ind.name == :nat_ind
    assert ind.reduction == %Reduction.NatInd{}
  end

  test "generates List eliminators from constructors" do
    spec = without_recursors(List.inductive_spec())

    assert [rec, ind] = Generate.list_eliminators(spec)
    assert rec.name == :list_rec
    assert rec.reduction == %Reduction.ListRec{}
    assert ind.name == :list_ind
    assert ind.reduction == %Reduction.ListInd{}
  end

  test "built-in libraries use generated eliminators" do
    assert Enum.map(Bool.inductive_spec().recursors, & &1.name) == [:bool_rec, :bool_ind]

    assert Nat.inductive_spec().recursors ==
             Generate.nat_eliminators(without_recursors(Nat.inductive_spec()))

    assert List.inductive_spec().recursors ==
             Generate.list_eliminators(without_recursors(List.inductive_spec()))
  end

  defp without_recursors(%Theoria.Inductive.Spec{} = spec) do
    %Theoria.Inductive.Spec{spec | recursors: []}
  end
end
