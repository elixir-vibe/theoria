defmodule Theoria.SimpTest do
  use ExUnit.Case, async: true

  alias Theoria.Prelude
  alias Theoria.Simp
  alias Theoria.Term

  test "simplifies once using generated equation rules" do
    {:ok, env} = Prelude.env()
    one = Term.app(Term.const(:succ), zero())
    term = Term.const(:nat_add) |> Term.app(zero()) |> Term.app(one)

    assert Simp.once(env, term) == {:ok, one, :"nat_add.eq_zero"}
  end

  test "normalizes repeatedly with a trace" do
    {:ok, env} = Prelude.env()
    one = Term.app(Term.const(:succ), zero())
    term = Term.const(:nat_add) |> Term.app(zero()) |> Term.app(one)

    assert %{term: ^one, steps: [{:"nat_add.eq_zero", ^one}], stopped: :normal} =
             Simp.normalize(env, term)
  end

  test "stops when fuel is exhausted" do
    {:ok, env} = Prelude.env()
    one = Term.app(Term.const(:succ), zero())
    term = Term.const(:nat_add) |> Term.app(zero()) |> Term.app(one)

    assert %{term: ^term, steps: [], stopped: :fuel} = Simp.normalize(env, term, max_steps: 0)
  end

  defp zero, do: Term.const(:zero)
end
