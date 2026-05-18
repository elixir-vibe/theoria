defmodule Theoria.SimpTest do
  use ExUnit.Case, async: true

  alias Theoria.Prelude
  alias Theoria.Simp
  alias Theoria.Simp.Database
  alias Theoria.Simp.Rule
  alias Theoria.Simp.Step
  alias Theoria.Term

  test "simplifies once using generated equation rules" do
    {:ok, env} = Prelude.env()
    one = Term.app(Term.const(:succ), zero())
    term = Term.const(:nat_add) |> Term.app(zero()) |> Term.app(one)

    assert {:ok, ^one, %Step{rule: :theoria__eq__nat_add__zero, before: ^term, after: ^one}} =
             Simp.once(env, term)
  end

  test "normalizes repeatedly with a trace" do
    {:ok, env} = Prelude.env()
    one = Term.app(Term.const(:succ), zero())
    term = Term.const(:nat_add) |> Term.app(zero()) |> Term.app(one)

    assert %{
             term: ^one,
             steps: [%Step{rule: :theoria__eq__nat_add__zero, after: ^one}],
             stopped: :normal
           } =
             Simp.normalize(env, term)
  end

  test "can simplify with the combined equation database" do
    {:ok, env} = Prelude.env()
    term = Term.app(Term.const(:bool_not), Term.const(true))

    assert {:ok, rewritten, %Step{}} = Simp.once(env, term, include_matchers: true)
    assert rewritten == Term.const(false)
  end

  test "simp database keeps matcher equations opt-in" do
    {:ok, env} = Prelude.env()

    equation_rules = Database.from_env_equations(env).rules
    all_rules = Database.from_env_all_equations(env).rules

    refute Enum.any?(
             equation_rules,
             &match?(%Rule{rewrite: %{name: :theoria__matcher_eq__bool_not_match_1__true}}, &1)
           )

    assert Enum.any?(
             all_rules,
             &match?(
               %Rule{
                 rewrite: %{name: :theoria__matcher_eq__bool_not_match_1__true},
                 source: :matcher_equation
               },
               &1
             )
           )
  end

  test "stops when fuel is exhausted" do
    {:ok, env} = Prelude.env()
    one = Term.app(Term.const(:succ), zero())
    term = Term.const(:nat_add) |> Term.app(zero()) |> Term.app(one)

    assert %{term: ^term, steps: [], stopped: :fuel} = Simp.normalize(env, term, max_steps: 0)
  end

  defp zero, do: Term.const(:zero)
end
