defmodule Theoria.Kernel.UniverseRuleTest do
  use ExUnit.Case, async: true

  alias Theoria.Env
  alias Theoria.Kernel

  import Theoria.Term

  test "proposition-valued forall lives in Prop" do
    proposition = forall(:p, sort(0), bvar(0))

    assert Kernel.infer(Env.new(), proposition) == {:ok, sort(0)}
  end

  test "implication between propositions lives in Prop" do
    implication = arrow(bvar(0), bvar(0))
    context = Theoria.Context.new() |> Theoria.Context.push(:p, sort(0))

    assert Kernel.infer(Env.new(), context, implication) == {:ok, sort(0)}
  end

  test "type-valued forall remains in the appropriate type universe" do
    type_identity = forall(:a, sort(1), arrow(bvar(0), bvar(0)))

    assert Kernel.infer(Env.new(), type_identity) == {:ok, sort(2)}
  end
end
