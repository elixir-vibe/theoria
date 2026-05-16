defmodule Theoria.Inductive.SpecBuilderTest do
  use ExUnit.Case, async: true

  alias Theoria.Env.Reduction
  alias Theoria.Inductive
  alias Theoria.Inductive.Spec

  import Theoria.Term

  test "builds specs with fluent helpers" do
    spec =
      :Box
      |> Spec.new(sort(1), universe_params: [:u])
      |> Spec.constructor(:box, const(:Box))
      |> Spec.recursor(:box_rec, const(:Box), %Reduction.NatRec{})

    assert spec.name == :Box
    assert Enum.map(spec.constructors, & &1.name) == [:box]
    assert Enum.map(spec.recursors, & &1.name) == [:box_rec]
    assert Inductive.validate(spec) == :ok
  end
end
