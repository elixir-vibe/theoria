defmodule Theoria.Normalize.HardeningTest do
  use ExUnit.Case, async: true

  alias Theoria.Env
  alias Theoria.Normalize
  alias Theoria.Prelude

  import Theoria.Term

  test "nat_rec normalizes nested successors" do
    {:ok, env} = Prelude.env()
    two = nat(2)

    term =
      const(:nat_rec, [1])
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
      const(:list_length, [1])
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

  test "normalization leaves stuck nat_rec applications intact" do
    {:ok, env} = Prelude.env()

    term =
      const(:nat_rec, [1])
      |> app(const(:Nat))
      |> app(const(:zero))
      |> app(succ_step())
      |> app(const(:unknown_nat))

    assert {:ok, normalized} = Normalize.normalize(env, term)
    assert normalized == term
  end

  test "definitional equality distinguishes different constructors" do
    {:ok, env} = Prelude.env()

    refute Normalize.defeq?(env, const(:zero), app(const(:succ), const(:zero)))
    refute Normalize.defeq?(env, const(true), const(false))
  end

  test "definition unfolding composes with primitive reductions" do
    {:ok, env} = Prelude.env()

    term =
      const(:nat_add)
      |> app(nat(2))
      |> app(nat(1))

    assert Normalize.defeq?(env, term, nat(3))
  end

  test "normalization limit stops unfolding loops" do
    env = Env.new() |> Env.put_definition(:loop, sort(0), const(:loop))

    assert {:error, error} = Normalize.normalize(env, const(:loop), max_steps: 3)
    assert Exception.message(error) == "normalization exceeded limit of 3 steps"
  end

  test "definitional equality returns false when normalization exceeds the limit" do
    env = Env.new() |> Env.put_definition(:loop, sort(0), const(:loop))

    refute Normalize.defeq?(env, const(:loop), const(:loop), max_steps: 3)
  end

  test "normalization fuel is shared across child terms" do
    env = Env.new() |> Env.put_definition(:loop, sort(0), const(:loop))
    term = eq(sort(0), const(:loop), const(:loop))

    assert {:error, error} = Normalize.normalize(env, term, max_steps: 4)
    assert Exception.message(error) == "normalization exceeded limit of 4 steps"
  end

  test "let zeta reduction spends normalization fuel" do
    term = let(:x, sort(0), sort(0), bvar(0))

    assert {:error, error} = Normalize.normalize(Env.new(), term, max_steps: 1)
    assert Exception.message(error) == "normalization exceeded limit of 1 steps"
  end

  defp nat(0), do: const(:zero)
  defp nat(n) when n > 0, do: app(const(:succ), nat(n - 1))

  defp list_nil(type) do
    app(const(:list_nil, [1]), type)
  end

  defp list_cons(type, head, tail) do
    const(:list_cons, [1])
    |> app(type)
    |> app(head)
    |> app(tail)
  end

  defp succ_step do
    lam(:_pred, const(:Nat), lam(:acc, const(:Nat), app(const(:succ), bvar(0))))
  end
end
