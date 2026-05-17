defmodule Theoria.Library.ListTest do
  use ExUnit.Case, async: true

  alias Theoria.Equation.Info
  alias Theoria.Kernel
  alias Theoria.Library.List
  alias Theoria.Normalize

  import Theoria.Term

  test "extends a nat environment with list declarations" do
    assert {:ok, env} = List.env()

    for name <- [:List, :list_nil, :list_cons, :list_length] do
      assert {:ok, _type} = Kernel.infer(env, const(name, [1]))
    end

    assert {:ok, _type} = Kernel.infer(env, const(:list_rec, [1, 1]))
    assert {:ok, _type} = Kernel.infer(env, const(:list_ind, [1, 1]))
  end

  test "compiled list definitions store equation metadata" do
    {:ok, env} = List.env()

    assert {:ok, %Info{} = length_info} = Info.get(env, :list_length)
    assert length_info.rec_arg_pos == 1
    assert length_info.level_params == [:u]

    assert {:ok, %Info{} = append_info} = Info.get(env, :list_append)
    assert append_info.rec_arg_pos == 1
    assert append_info.level_params == [:u]
  end

  test "List maps Type 0 to Type 0" do
    {:ok, env} = List.env()

    assert {:ok, type} = Kernel.infer(env, app(const(:List, [1]), const(:Nat)))
    assert type == sort(1)
  end

  test "list_rec reduces nil" do
    {:ok, env} = List.env()

    term =
      const(:list_rec, [1, 1])
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
      const(:list_rec, [1, 1])
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
      const(:list_length, [1])
      |> app(const(:Nat))
      |> app(list_nil(const(:Nat)))

    assert Normalize.defeq?(env, term, const(:zero))
  end

  defp list_nil(type) do
    app(const(:list_nil, [1]), type)
  end

  defp list_cons(type, head, tail) do
    const(:list_cons, [1])
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
        app(const(:List, [1]), const(:Nat)),
        lam(:acc, const(:Nat), app(const(:succ), bvar(0)))
      )
    )
  end
end
