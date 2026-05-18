defmodule Theoria.SimpTest do
  use ExUnit.Case, async: true

  alias Theoria.Equation.Identity
  alias Theoria.Kernel
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

    assert {:ok, ^one,
            %Step{
              rule: %Identity{kind: :equation, owner: :nat_add, target: :zero},
              before: ^term,
              after: ^one
            }} =
             Simp.once(env, term)
  end

  test "normalizes repeatedly with a trace" do
    {:ok, env} = Prelude.env()
    one = Term.app(Term.const(:succ), zero())
    term = Term.const(:nat_add) |> Term.app(zero()) |> Term.app(one)

    assert %{
             term: ^one,
             steps: [
               %Step{
                 rule: %Identity{kind: :equation, owner: :nat_add, target: :zero},
                 after: ^one
               }
             ],
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

    matcher_equation = Identity.matcher_equation(:bool_not_match_1, true)

    refute Enum.any?(equation_rules, &match?(%Rule{rewrite: %{name: ^matcher_equation}}, &1))

    assert Enum.any?(
             all_rules,
             &match?(%Rule{rewrite: %{name: ^matcher_equation}, source: :matcher_equation}, &1)
           )
  end

  test "normalizes with checked proof artifact when requested" do
    {:ok, env} = Prelude.env()
    one = Term.app(Term.const(:succ), zero())
    term = Term.const(:nat_add) |> Term.app(zero()) |> Term.app(one)

    result = Simp.normalize(env, term, prove: true)

    assert result.term == one
    assert %Theoria.Equation.Realized{identity: %Identity{kind: :simp}} = result.realized
    assert result.proof == result.realized.proof
    assert :ok = Kernel.check(env, result.realized.proof, result.realized.type)
    assert [%Step{proof: %Term.Refl{}}] = result.steps
  end

  test "realizes and installs simp equality under a user theorem name" do
    {:ok, env} = Prelude.env()
    one = Term.app(Term.const(:succ), zero())
    term = Term.const(:nat_add) |> Term.app(zero()) |> Term.app(one)

    assert {:ok, realized} = Simp.realize(env, term)
    assert %Identity{kind: :simp} = realized.identity

    assert {:ok, env, theorem} = Simp.add_theorem(env, :nat_add_zero_simp, term)
    assert theorem.name == :nat_add_zero_simp
    assert {:ok, _constant} = Theoria.Env.fetch(env, :nat_add_zero_simp)
  end

  test "stops when fuel is exhausted" do
    {:ok, env} = Prelude.env()
    one = Term.app(Term.const(:succ), zero())
    term = Term.const(:nat_add) |> Term.app(zero()) |> Term.app(one)

    assert %{term: ^term, steps: [], stopped: :fuel} = Simp.normalize(env, term, max_steps: 0)
  end

  defp zero, do: Term.const(:zero)
end
