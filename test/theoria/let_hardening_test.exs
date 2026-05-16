defmodule Theoria.LetHardeningTest do
  use ExUnit.Case, async: true

  alias Theoria.Elaborator
  alias Theoria.Env
  alias Theoria.Kernel
  alias Theoria.Normalize
  alias Theoria.Syntax, as: S

  import Theoria.Term

  test "let value can reference an outer binder" do
    term =
      S.lam(:p, S.sort(0), S.let(:x, S.sort(0), S.var(:p), S.var(:x)))

    assert Elaborator.elaborate(term) ==
             {:ok, lam(:p, sort(0), let(:x, sort(0), bvar(0), bvar(0)))}
  end

  test "let type cannot reference the let-bound name" do
    term = S.let(:x, S.var(:x), S.const(:value), S.var(:x))

    assert {:error, error} = Elaborator.elaborate(term)
    assert error.reason == :unbound_name
    assert error.details == [name: :x, context: []]
  end

  test "let value cannot reference the let-bound name" do
    term = S.let(:x, S.sort(0), S.var(:x), S.var(:x))

    assert {:error, error} = Elaborator.elaborate(term)
    assert error.reason == :unbound_name
    assert error.details == [name: :x, context: []]
  end

  test "nested lets shadow correctly" do
    term =
      S.let(:x, S.sort(0), S.const(:outer), S.let(:x, S.sort(0), S.const(:inner), S.var(:x)))

    assert Elaborator.elaborate(term) ==
             {:ok, let(:x, sort(0), const(:outer), let(:x, sort(0), const(:inner), bvar(0)))}
  end

  test "zeta reduction handles nested lets" do
    term = let(:x, sort(0), const(:outer), let(:x, sort(0), const(:inner), bvar(0)))

    assert Normalize.normalize(Env.new(), term) == {:ok, const(:inner)}
  end

  test "let body type can depend on the let value" do
    env = Env.new()
    type = sort(1)
    value = sort(0)
    body = bvar(0)
    term = let(:x, type, value, body)

    assert Kernel.infer(env, term) == {:ok, sort(1)}
  end
end
