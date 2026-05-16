defmodule Theoria.ErrorTest do
  use ExUnit.Case, async: true

  alias Theoria.Elaborator
  alias Theoria.Env
  alias Theoria.Kernel

  import Theoria.Term

  test "formats type mismatch with pretty terms" do
    assert {:error, error} = Kernel.check(Env.new(), sort(0), sort(2))

    assert Exception.message(error) == "type mismatch\n\nactual:\n  Type 1\n\nexpected:\n  Type 2"
  end

  test "formats unknown constants" do
    assert {:error, error} = Kernel.infer(Env.new(), const(:missing))

    assert Exception.message(error) == "unknown constant: missing"
  end

  test "formats unbound variables" do
    assert {:error, error} = Kernel.infer(Env.new(), bvar(2))

    assert Exception.message(error) == "unbound de Bruijn variable #2 in context of size 0"
  end

  test "formats non-function application" do
    context = Theoria.Context.new() |> Theoria.Context.push(:x, sort(0))

    assert {:error, error} = Kernel.infer(Env.new(), context, app(bvar(0), bvar(0)))

    assert Exception.message(error) == "expected a function type, got:\n  Prop"
  end

  test "formats expected sort errors" do
    {:ok, env} = Kernel.add_constant(Env.new(), :Nat, sort(0))
    {:ok, env} = Kernel.add_constant(env, :zero, const(:Nat))

    assert {:error, error} = Kernel.add_constant(env, :bad, const(:zero))

    assert Exception.message(error) == "expected a type/sort, got:\n  Nat"
  end

  test "formats unbound elaborator names" do
    assert {:error, error} = Elaborator.elaborate(Theoria.Syntax.var(:missing))

    assert Exception.message(error) == "unbound name: missing (context: [])"
  end
end
