defmodule Theoria.Library.List.DependentInductionTest do
  use ExUnit.Case, async: true

  alias Theoria.Kernel
  alias Theoria.Library.List
  alias Theoria.Normalize

  import Theoria.Term

  test "list_ind type checks" do
    {:ok, env} = List.env()

    assert {:ok, _type} = Kernel.infer(env, const(:list_ind, [1, 1]))
  end

  test "list_ind reduces nil" do
    {:ok, env} = List.env()

    term =
      const(:list_ind, [1, 1])
      |> app(const(:Nat))
      |> app(constant_nat_motive())
      |> app(const(:zero))
      |> app(length_step())
      |> app(list_nil(const(:Nat)))

    assert Normalize.defeq?(env, term, const(:zero))
  end

  test "list_ind reduces cons" do
    {:ok, env} = List.env()
    one = app(const(:succ), const(:zero))

    term =
      const(:list_ind, [1, 1])
      |> app(const(:Nat))
      |> app(constant_nat_motive())
      |> app(const(:zero))
      |> app(length_step())
      |> app(list_cons(const(:Nat), const(:zero), list_nil(const(:Nat))))

    assert Normalize.defeq?(env, term, one)
  end

  test "list_ind checks a dependent equality motive" do
    {:ok, env} = List.env()

    proof =
      const(:list_ind, [1, 0])
      |> app(const(:Nat))
      |> app(reflexive_motive())
      |> app(refl(list_nil(const(:Nat))))
      |> app(reflexive_step())

    expected = forall(:xs, list_type(const(:Nat)), eq(list_type(const(:Nat)), bvar(0), bvar(0)))

    assert :ok = Kernel.check(env, proof, expected)
  end

  defp constant_nat_motive do
    lam(:_xs, list_type(const(:Nat)), const(:Nat))
  end

  defp length_step do
    lam(
      :_head,
      const(:Nat),
      lam(
        :_tail,
        list_type(const(:Nat)),
        lam(:acc, const(:Nat), app(const(:succ), bvar(0)))
      )
    )
  end

  defp reflexive_motive do
    lam(:xs, list_type(const(:Nat)), eq(list_type(const(:Nat)), bvar(0), bvar(0)))
  end

  defp reflexive_step do
    lam(
      :x,
      const(:Nat),
      lam(
        :xs,
        list_type(const(:Nat)),
        lam(
          :_ih,
          eq(list_type(const(:Nat)), bvar(0), bvar(0)),
          refl(list_cons(const(:Nat), bvar(2), bvar(1)))
        )
      )
    )
  end

  defp list_type(type), do: app(const(:List, [1]), type)
  defp list_nil(type), do: app(const(:list_nil, [1]), type)

  defp list_cons(type, head, tail) do
    const(:list_cons, [1])
    |> app(type)
    |> app(head)
    |> app(tail)
  end
end
