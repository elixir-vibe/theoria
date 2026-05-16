defmodule Theoria.Library.ListTest do
  use ExUnit.Case, async: true

  alias Theoria.Kernel
  alias Theoria.Library.List
  alias Theoria.Normalize

  import Theoria.Term

  test "extends a nat environment with list declarations" do
    assert {:ok, env} = List.env()

    for name <- [:List, :list_nil, :list_cons, :list_rec, :list_length] do
      assert {:ok, _type} = Kernel.infer(env, const(name))
    end
  end

  test "List maps Type 0 to Type 0" do
    {:ok, env} = List.env()

    assert {:ok, type} = Kernel.infer(env, app(const(:List), const(:Nat)))
    assert type == sort(1)
  end

  test "list_rec reduces nil" do
    {:ok, env} = List.env()

    term =
      const(:list_rec)
      |> app(const(:Nat))
      |> app(const(:Nat))
      |> app(const(:zero))
      |> app(length_step())
      |> app(list_nil(const(:Nat)))

    assert Normalize.defeq?(env, term, const(:zero))
  end

  test "list_rec reduces cons" do
    {:ok, env} = List.env()
    one = app(const(:succ), const(:zero))

    term =
      const(:list_rec)
      |> app(const(:Nat))
      |> app(const(:Nat))
      |> app(const(:zero))
      |> app(length_step())
      |> app(list_cons(const(:Nat), const(:zero), list_nil(const(:Nat))))

    assert Normalize.defeq?(env, term, one)
  end

  test "list_length computes nil" do
    {:ok, env} = List.env()

    term =
      const(:list_length)
      |> app(const(:Nat))
      |> app(list_nil(const(:Nat)))

    assert Normalize.defeq?(env, term, const(:zero))
  end

  defp list_nil(type) do
    app(const(:list_nil), type)
  end

  defp list_cons(type, head, tail) do
    const(:list_cons)
    |> app(type)
    |> app(head)
    |> app(tail)
  end

  defp length_step do
    lam(
      :_head,
      const(:Nat),
      lam(
        :_tail,
        app(const(:List), const(:Nat)),
        lam(:acc, const(:Nat), app(const(:succ), bvar(0)))
      )
    )
  end
end
