defmodule Theoria.Library.VecTest do
  use ExUnit.Case, async: true

  alias Theoria.Env
  alias Theoria.Equation.Matcher.Eqns, as: MatcherEqns
  alias Theoria.Equation.Matcher.Indexed.Package, as: IndexedPackage
  alias Theoria.Equation.Matcher.Indexed.Realization, as: IndexedRealization
  alias Theoria.Equation.Name
  alias Theoria.Inductive
  alias Theoria.Kernel
  alias Theoria.Library.Vec
  alias Theoria.Normalize
  alias Theoria.Rewrite.Database, as: RewriteDatabase
  alias Theoria.Simp.Database, as: SimpDatabase
  alias Theoria.Term

  import Theoria.DSL

  test "declares Vec as an indexed inductive family" do
    spec = Vec.inductive_spec()

    assert spec.name == :Vec
    assert Enum.map(spec.parameters, & &1.name) == [:a]
    assert Enum.map(spec.indices, & &1.name) == [:n]
    assert Enum.map(spec.constructors, & &1.name) == [:vec_nil, :vec_cons]
    assert spec.recursors == []
  end

  test "installs Vec declarations and indexed eliminator metadata" do
    {:ok, env} = Vec.env()

    assert Env.inductive?(env, :Vec)
    assert Env.constructor?(env, :vec_nil)
    assert Env.constructor?(env, :vec_cons)
    assert Env.recursor?(env, :vec_ind)

    assert {:ok, recursor} = Env.fetch_recursor(env, :vec_ind)
    assert recursor.num_params == 1
    assert recursor.num_indices == 1

    assert Enum.map(recursor.rules, &{&1.constructor, &1.field_count}) == [
             vec_nil: 0,
             vec_cons: 3
           ]
  end

  test "Vec environment verifies against completed inductive spec" do
    {:ok, spec} = Inductive.complete(Vec.inductive_spec())
    {:ok, env} = Vec.env()

    assert Inductive.verify_env(env, spec) == :ok
  end

  test "Vec induction reduces nil and cons" do
    {:ok, env} = Vec.env()
    nil_vec = term(do: app(const(:vec_nil, [1]), nat())) |> elab!()

    cons =
      app_all(
        [Term.const(:Nat), Term.const(:zero), Term.const(:zero), nil_vec],
        Term.const(:vec_cons, [1])
      )

    assert Normalize.defeq?(
             env,
             vec_ind_term(index: Term.const(:zero), major: nil_vec),
             Term.const(:zero)
           )

    assert Normalize.defeq?(
             env,
             vec_ind_term(index: Term.app(Term.const(:succ), Term.const(:zero)), major: cons),
             Term.app(Term.const(:succ), Term.const(:zero))
           )
  end

  test "Vec induction checks an equality-valued motive" do
    {:ok, env} = Vec.env()
    nil_vec = term(do: app(const(:vec_nil, [0]), nat())) |> elab!()

    cons =
      app_all(
        [Term.const(:Nat), Term.const(:zero), Term.const(:zero), nil_vec],
        Term.const(:vec_cons, [0])
      )

    term =
      vec_equality_ind_term(index: Term.app(Term.const(:succ), Term.const(:zero)), major: cons)

    expected =
      Term.eq(
        Term.const(:Nat),
        Term.app(Term.const(:succ), Term.const(:zero)),
        Term.app(Term.const(:succ), Term.const(:zero))
      )

    assert Normalize.defeq?(env, term, Term.refl(Term.app(Term.const(:succ), Term.const(:zero))))
    assert Kernel.check(env, expected, Term.sort(0)) == :ok
  end

  test "Vec indexed matcher can be installed explicitly without changing the default env" do
    {:ok, default_env} = Vec.env()
    assert Env.fetch_matcher(default_env, :vec_match) == :error

    {:ok, env} = Vec.env_with_indexed_matcher()
    assert {:ok, matcher} = Env.fetch_matcher(env, :vec_match)
    assert matcher.mode == :indexed_matcher
    assert matcher.equation_names == []
    assert {:ok, _replayed} = Kernel.validate_env(env)

    info = Vec.indexed_matcher_info(:vec_match)
    assert {:ok, package} = IndexedPackage.build(info, env)
    assert :ok = IndexedPackage.validate(package)
    assert {:ok, theorems} = IndexedRealization.realize_all(package)

    assert Enum.map(theorems, & &1.name) == [
             Name.indexed_matcher_equation(:vec_match, :vec_nil),
             Name.indexed_matcher_equation(:vec_match, :vec_cons)
           ]

    assert {:ok, [nil_equation, cons_equation]} = MatcherEqns.indexed_statements(info, env)
    assert nil_equation.statement_status == :planned
    assert cons_equation.statement_status == :planned
  end

  test "Vec indexed matcher equation theorems can be installed opt-in" do
    {:ok, env} = Vec.env_with_indexed_matcher(install_equations: true)

    nil_equation = Name.indexed_matcher_equation(:vec_match, :vec_nil)
    cons_equation = Name.indexed_matcher_equation(:vec_match, :vec_cons)

    assert {:ok, _constant} = Env.fetch(env, nil_equation)
    assert {:ok, _constant} = Env.fetch(env, cons_equation)
    assert {:ok, matcher} = Env.fetch_matcher(env, :vec_match)

    assert matcher.equation_names == [nil_equation, cons_equation]

    assert length(RewriteDatabase.from_env_indexed_matcher_equations(env).rules) == 2
    assert length(SimpDatabase.from_env_indexed_matcher_equations(env).rules) == 2

    default_rules = RewriteDatabase.from_env_all_equations(env).rules

    indexed_rules =
      RewriteDatabase.from_env_all_equations(env, include_indexed_matchers: true).rules

    assert length(indexed_rules) == length(default_rules) + 2
    refute Enum.any?(default_rules, &match?(%{id: %{kind: :indexed_matcher_equation}}, &1))
    assert Enum.any?(indexed_rules, &match?(%{id: %{kind: :indexed_matcher_equation}}, &1))
    assert {:ok, _replayed} = Kernel.validate_env(env)
  end

  test "Prelude does not install experimental Vec indexed matchers" do
    {:ok, env} = Theoria.Prelude.env()
    assert Env.fetch_matcher(env, :vec_match) == :error
  end

  test "Vec requires Nat dependencies" do
    assert {:error, error} = Vec.extend(Env.new())
    assert error.reason == :invalid_inductive
  end

  defp vec_ind_term(opts) do
    index = Keyword.fetch!(opts, :index)
    major = Keyword.fetch!(opts, :major)
    motive = vec_nat_motive() |> elab!()
    cons_case = vec_nat_cons_case() |> elab!()

    [Term.const(:Nat), motive, Term.const(:zero), cons_case, index, major]
    |> app_all(Term.const(:vec_ind, [1]))
  end

  defp vec_nat_motive do
    term do
      lam :n, nat() do
        lam :xs, app(app(const(:Vec, [1]), nat()), n) do
          nat()
        end
      end
    end
  end

  defp vec_nat_cons_case do
    term do
      lam :head, nat() do
        lam :n, nat() do
          lam :tail, app(app(const(:Vec, [1]), nat()), n) do
            lam :ih, nat() do
              app(succ, ih)
            end
          end
        end
      end
    end
  end

  defp vec_equality_ind_term(opts) do
    index = Keyword.fetch!(opts, :index)
    major = Keyword.fetch!(opts, :major)
    motive = vec_equality_motive() |> elab!()
    cons_case = vec_equality_cons_case() |> elab!()

    [Term.const(:Nat), motive, Term.refl(Term.const(:zero)), cons_case, index, major]
    |> app_all(Term.const(:vec_ind, [0]))
  end

  defp vec_equality_motive do
    term do
      lam :n, nat() do
        lam :xs, app(app(const(:Vec, [0]), nat()), n) do
          eq(nat(), n, n)
        end
      end
    end
  end

  defp vec_equality_cons_case do
    term do
      lam :_head, nat() do
        lam :n, nat() do
          lam :_tail, app(app(const(:Vec, [0]), nat()), n) do
            lam :_ih, eq(nat(), n, n) do
              refl(app(succ, n))
            end
          end
        end
      end
    end
  end

  defp app_all(args, fun), do: Enum.reduce(args, fun, &Term.app(&2, &1))
end
