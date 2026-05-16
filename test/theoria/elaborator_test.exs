defmodule Theoria.ElaboratorTest do
  use ExUnit.Case, async: true

  alias Theoria.Elaborator
  alias Theoria.Env
  alias Theoria.Kernel
  alias Theoria.Syntax, as: S

  import Theoria.Term

  test "resolves named variables to de Bruijn indices" do
    term =
      S.lam(:x, S.sort(0), S.lam(:y, S.var(:x), S.var(:x)))

    assert {:ok, elaborated} = Elaborator.elaborate(term)
    assert elaborated == lam(:x, sort(0), lam(:y, bvar(0), bvar(1)))
  end

  test "resolves shadowing to the nearest binder" do
    term =
      S.lam(:x, S.sort(0), S.lam(:x, S.sort(0), S.var(:x)))

    assert {:ok, elaborated} = Elaborator.elaborate(term)
    assert elaborated == lam(:x, sort(0), lam(:x, sort(0), bvar(0)))
  end

  test "rejects unbound names" do
    assert {:error, error} = Elaborator.elaborate(S.var(:missing))
    assert error.reason == :unbound_name
  end

  test "elaborates an identity proof that the kernel accepts" do
    type =
      S.forall(:a, S.sort(0), S.forall(:x, S.var(:a), S.var(:a)))

    proof =
      S.lam(:a, S.sort(0), S.lam(:x, S.var(:a), S.var(:x)))

    assert {:ok, type} = Elaborator.elaborate(type)
    assert {:ok, proof} = Elaborator.elaborate(proof)
    assert :ok = Kernel.check(Env.new(), proof, type)
  end

  test "elaborates equality and reflexivity" do
    type =
      S.forall(:a, S.sort(0), S.forall(:x, S.var(:a), S.eq(S.var(:a), S.var(:x), S.var(:x))))

    proof =
      S.lam(:a, S.sort(0), S.lam(:x, S.var(:a), S.refl(S.var(:x))))

    assert {:ok, type} = Elaborator.elaborate(type)
    assert {:ok, proof} = Elaborator.elaborate(proof)
    assert :ok = Kernel.check(Env.new(), proof, type)
  end
end
