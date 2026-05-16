defmodule Theoria.DSLTest do
  use ExUnit.Case, async: true

  alias Theoria.Env
  alias Theoria.Kernel
  alias Theoria.Syntax, as: S

  import Theoria.DSL

  test "constructs binders with do blocks" do
    term =
      forall :a, type(0) do
        forall :x, var(:a) do
          var(:a)
        end
      end

    assert term ==
             S.forall(:a, S.sort(0), S.forall(:x, S.var(:a), S.var(:a)))
  end

  test "supports variable-looking binder names" do
    term =
      forall a, type(0) do
        lam x, var(:a) do
          var(:x)
        end
      end

    assert term ==
             S.forall(:a, S.sort(0), S.lam(:x, S.var(:a), S.var(:x)))
  end

  test "call applies arguments left-associatively" do
    assert call(const(:and), var(:p), var(:q)) ==
             S.app(S.app(S.const(:and), S.var(:p)), S.var(:q))
  end

  test "elaborates and checks an identity proof" do
    type =
      forall :a, type(0) do
        forall :x, var(:a) do
          var(:a)
        end
      end

    proof =
      lam :a, type(0) do
        lam :x, var(:a) do
          var(:x)
        end
      end

    assert {:ok, type} = elab(type)
    assert {:ok, proof} = elab(proof)
    assert :ok = Kernel.check(Env.new(), proof, type)
  end

  test "elaborates and checks equality reflexivity" do
    type =
      forall :a, type(0) do
        forall :x, var(:a) do
          eq(var(:a), var(:x), var(:x))
        end
      end

    proof =
      lam :a, type(0) do
        lam :x, var(:a) do
          refl(var(:x))
        end
      end

    assert :ok = Kernel.check(Env.new(), elab!(proof), elab!(type))
  end
end
