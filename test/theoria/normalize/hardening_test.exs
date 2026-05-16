defmodule Theoria.Normalize.HardeningTest do
  use ExUnit.Case, async: true

  alias Theoria.Normalize
  alias Theoria.Prelude

  import Theoria.Term

  test "nat_rec normalizes nested successors" do
    {:ok, env} = Prelude.env()
    two = nat(2)

    term =
      const(:nat_rec)
      |> app(const(:Nat))
      |> app(const(:zero))
      |> app(succ_step())
      |> app(two)

    assert Normalize.defeq?(env, term, two)
  end

  test "list_length normalizes multi-element lists" do
    {:ok, env} = Prelude.env()

    list =
      list_cons(
        const(:Nat),
        const(:zero),
        list_cons(const(:Nat), app(const(:succ), const(:zero)), list_nil(const(:Nat)))
      )

    term =
      const(:list_length)
      |> app(const(:Nat))
      |> app(list)

    assert Normalize.defeq?(env, term, nat(2))
  end

  test "substitution preserves free variables under binders" do
    body = lam(:y, sort(0), bvar(1))

    assert subst_top(body, bvar(0)) == lam(:y, sort(0), bvar(1))
  end

  test "negative shifts are rejected instead of producing invalid variables" do
    assert_raise ArgumentError, "de Bruijn shift produced a negative index", fn ->
      shift(bvar(0), -1)
    end
  end

  defp nat(0), do: const(:zero)
  defp nat(n) when n > 0, do: app(const(:succ), nat(n - 1))

  defp list_nil(type) do
    app(const(:list_nil), type)
  end

  defp list_cons(type, head, tail) do
    const(:list_cons)
    |> app(type)
    |> app(head)
    |> app(tail)
  end

  defp succ_step do
    lam(:_pred, const(:Nat), lam(:acc, const(:Nat), app(const(:succ), bvar(0))))
  end
end
