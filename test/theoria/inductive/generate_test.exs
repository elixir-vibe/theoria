defmodule Theoria.Inductive.GenerateTest do
  use ExUnit.Case, async: true

  alias Theoria.Env.Reduction
  alias Theoria.Inductive.Generate
  alias Theoria.Inductive.Spec
  alias Theoria.Library.Bool

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

  test "Bool library uses generated eliminators" do
    assert Enum.map(Bool.inductive_spec().recursors, & &1.name) == [:bool_rec, :bool_ind]
  end
end
