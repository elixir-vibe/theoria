defmodule Theoria.Library.NatTest do
  use ExUnit.Case, async: true

  alias Theoria.Kernel
  alias Theoria.Library.Nat
  alias Theoria.Normalize

  import Theoria.Term

  test "extends an environment with nat declarations" do
    assert {:ok, env} = Nat.env()

    for name <- [:Nat, :zero, :succ, :nat_add] do
      assert {:ok, _type} = Kernel.infer(env, const(name))
    end

    assert {:ok, _type} = Kernel.infer(env, const(:nat_rec, [1]))
    assert {:ok, _type} = Kernel.infer(env, const(:nat_ind, [1]))
  end

  test "Nat lives in Type 0" do
    {:ok, env} = Nat.env()

    assert {:ok, type} = Kernel.infer(env, const(:Nat))
    assert type == sort(1)
  end

  test "nat_rec reduces zero" do
    {:ok, env} = Nat.env()

    term =
      const(:nat_rec, [1])
      |> app(const(:Nat))
      |> app(const(:zero))
      |> app(succ_step())
      |> app(const(:zero))

    assert Normalize.defeq?(env, term, const(:zero))
  end

  test "nat_rec reduces successor" do
    {:ok, env} = Nat.env()

    one = app(const(:succ), const(:zero))

    term =
      const(:nat_rec, [1])
      |> app(const(:Nat))
      |> app(const(:zero))
      |> app(succ_step())
      |> app(one)

    assert Normalize.defeq?(env, term, one)
  end

  defp succ_step do
    lam(:_pred, const(:Nat), lam(:acc, const(:Nat), app(const(:succ), bvar(0))))
  end
end
