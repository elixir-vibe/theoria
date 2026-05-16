defmodule Theoria.Inductive.ConstructorResultTest do
  use ExUnit.Case, async: true

  alias Theoria.Inductive.Constructor
  alias Theoria.Library.{List, Nat}

  import Theoria.Term

  test "decomposes nullary constructor results" do
    spec = Nat.inductive_spec()
    constructor = Enum.find(spec.constructors, &(&1.name == :zero))

    assert {:ok, result} = Constructor.result(constructor, spec)
    assert result.binders == []
    assert result.head == const(:Nat)
    assert result.arguments == []
    assert result.parameters == []
    assert result.indices == []
  end

  test "decomposes parameterized constructor results" do
    spec = List.inductive_spec()
    constructor = Enum.find(spec.constructors, &(&1.name == :list_cons))

    assert {:ok, result} = Constructor.result(constructor, spec)
    assert Enum.map(result.binders, & &1.name) == [:a, :_, :_]
    assert result.head == const(:List, [Theoria.Level.param(:u)])
    assert result.arguments == [bvar(2)]
    assert result.parameters == [bvar(2)]
    assert result.indices == []
  end
end
