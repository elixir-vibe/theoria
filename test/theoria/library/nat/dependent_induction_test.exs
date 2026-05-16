defmodule Theoria.Library.Nat.DependentInductionTest do
  use ExUnit.Case, async: true

  alias Theoria.Kernel
  alias Theoria.Library.Nat
  alias Theoria.Normalize

  import Theoria.Term

  test "nat_ind type checks" do
    {:ok, env} = Nat.env()

    assert {:ok, _type} = Kernel.infer(env, const(:nat_ind, [1]))
  end

  test "nat_ind reduces zero" do
    {:ok, env} = Nat.env()

    term =
      const(:nat_ind, [1])
      |> app(constant_nat_motive())
      |> app(const(:zero))
      |> app(succ_step())
      |> app(const(:zero))

    assert Normalize.defeq?(env, term, const(:zero))
  end

  test "nat_ind reduces successor" do
    {:ok, env} = Nat.env()
    one = app(const(:succ), const(:zero))

    term =
      const(:nat_ind, [1])
      |> app(constant_nat_motive())
      |> app(const(:zero))
      |> app(succ_step())
      |> app(one)

    assert Normalize.defeq?(env, term, one)
  end

  test "nat_ind checks a dependent equality motive" do
    {:ok, env} = Nat.env()

    proof =
      const(:nat_ind, [0])
      |> app(reflexive_motive())
      |> app(refl(const(:zero)))
      |> app(reflexive_step())

    expected = forall(:n, const(:Nat), eq(const(:Nat), bvar(0), bvar(0)))

    assert :ok = Kernel.check(env, proof, expected)
  end

  defp constant_nat_motive do
    lam(:_n, const(:Nat), const(:Nat))
  end

  defp succ_step do
    lam(:n, const(:Nat), lam(:acc, const(:Nat), app(const(:succ), bvar(0))))
  end

  defp reflexive_motive do
    lam(:n, const(:Nat), eq(const(:Nat), bvar(0), bvar(0)))
  end

  defp reflexive_step do
    lam(
      :n,
      const(:Nat),
      lam(
        :_ih,
        eq(const(:Nat), bvar(0), bvar(0)),
        refl(app(const(:succ), bvar(1)))
      )
    )
  end
end
