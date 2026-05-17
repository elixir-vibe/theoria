defmodule Theoria.SimpTest do
  use ExUnit.Case, async: true

  alias Theoria.Prelude
  alias Theoria.Simp
  alias Theoria.Simp.Step
  alias Theoria.Term

  test "simplifies once using generated equation rules" do
    {:ok, env} = Prelude.env()
    one = Term.app(Term.const(:succ), zero())
    term = Term.const(:nat_add) |> Term.app(zero()) |> Term.app(one)

    assert {:ok, ^one, %Step{rule: :"nat_add.eq_zero", before: ^term, after: ^one}} =
             Simp.once(env, term)
  end

  test "normalizes repeatedly with a trace" do
    {:ok, env} = Prelude.env()
    one = Term.app(Term.const(:succ), zero())
    term = Term.const(:nat_add) |> Term.app(zero()) |> Term.app(one)

    assert %{term: ^one, steps: [%Step{rule: :"nat_add.eq_zero", after: ^one}], stopped: :normal} =
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
