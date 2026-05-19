defmodule Theoria.RewriteTest do
  use ExUnit.Case, async: true

  alias Theoria.Equation.Identity
  alias Theoria.Equation.Lemma
  alias Theoria.Kernel
  alias Theoria.Prelude
  alias Theoria.Rewrite
  alias Theoria.Rewrite.{Database, Proof, Rule}
  alias Theoria.Term

  test "rewrites the first structural occurrence forward" do
    equality = Term.eq(Term.const(:Nat), Term.const(:zero), Term.const(:one))
    term = Term.app(Term.const(:succ), Term.const(:zero))

    assert Rewrite.once(term, equality) ==
             {:ok, Term.app(Term.const(:succ), Term.const(:one))}
  end

  test "rewrites backward" do
    equality = Term.eq(Term.const(:Nat), Term.const(:zero), Term.const(:one))
    term = Term.app(Term.const(:succ), Term.const(:one))

    assert Rewrite.once(term, equality, direction: Rewrite.direction!(:backward)) ==
             {:ok, Term.app(Term.const(:succ), Term.const(:zero))}
  end

  test "reports no replacement" do
    equality = Term.eq(Term.const(:Nat), Term.const(:zero), Term.const(:one))

    assert Rewrite.once(Term.const(:two), equality) == :not_found
  end

  test "returns rewrite-step paths" do
    zero = Term.const(:zero)
    one = Term.const(:one)
    succ_one = Term.app(Term.const(:succ), one)
    lemma = Lemma.new(:zero_to_one, zero, one)
    rule = Rule.from_lemma(lemma, Term.const(:Nat))

    assert {:ok, %Theoria.Rewrite.Step{path: [], after: ^one, substitution: %{}}} =
             Rewrite.once_with_step(zero, rule)

    term = Term.app(Term.const(:succ), zero)

    assert {:ok, %Theoria.Rewrite.Step{path: [:arg], after: ^succ_one, substitution: %{}}} =
             Rewrite.once_with_step(term, rule)
  end

  test "equality-left rewrite steps can carry checked proof" do
    {:ok, env} = Prelude.env()
    zero = Term.const(:zero)
    equality = Term.eq(Term.const(:Nat), zero, zero)
    rule = Rule.new(:same_zero, equality, proof: Term.refl(zero))
    term = Term.eq(Term.const(:Nat), zero, zero)

    assert {:ok, step} = Rewrite.once_with_step(term, rule)
    assert step.path == [:left]
    assert %Term.EqRec{} = Proof.for_step(env, step)
  end

  test "equality-right rewrite steps can carry checked proof" do
    {:ok, env} = Prelude.env()
    bool_true = Term.const(true)
    equality = Term.eq(Term.const(:Bool), bool_true, bool_true)
    rule = Rule.new(:same_true, equality, proof: Term.refl(bool_true))
    term = Term.eq(Term.const(:Bool), Term.const(false), bool_true)

    assert {:ok, step} = Rewrite.once_with_step(term, rule)
    assert step.path == [:right]
    assert %Term.EqRec{} = Proof.for_step(env, step)
  end

  test "EqRec proof rewrite steps report explicit proof boundary" do
    {:ok, env} = Prelude.env()
    zero = Term.const(:zero)
    nat = Term.const(:Nat)
    motive = Term.lam(:n, nat, Term.shift(nat, 1))
    eq_rec = Term.eq_rec(nat, motive, zero, Term.refl(zero))
    equality = Term.eq(Term.eq(nat, zero, zero), Term.refl(zero), Term.refl(zero))
    rule = Rule.new(:same_refl, equality, proof: Term.refl(Term.refl(zero)))

    assert {:ok, step} = Rewrite.once_with_step(eq_rec, rule)
    assert step.path == [:proof]

    assert %{proof_result: %{status: :checked, capability: %{reason: :eq_rec_proof_congruence}}} =
             Proof.attach(env, step)
  end

  test "EqRec proof rewrite steps can carry checked non-definitional proof" do
    {:ok, env} = Prelude.env()
    zero = Term.const(:zero)
    nat = Term.const(:Nat)
    motive = Term.lam(:n, nat, Term.shift(nat, 1))
    equality = Term.eq(nat, zero, zero)
    h1 = Term.const(:h1)
    h2 = Term.const(:h2)
    proof_equality = Term.eq(equality, h1, h2)

    {:ok, env} = Kernel.add_axiom(env, :h1, equality)
    {:ok, env} = Kernel.add_axiom(env, :h2, equality)
    {:ok, env} = Kernel.add_axiom(env, :h1_eq_h2, proof_equality)

    eq_rec = Term.eq_rec(nat, motive, zero, h1)
    rule = Rule.new(:h1_to_h2, proof_equality, proof: Term.const(:h1_eq_h2))

    assert {:ok, step} = Rewrite.once_with_step(eq_rec, rule)
    assert step.path == [:proof]
    assert step.after == Term.eq_rec(nat, motive, zero, h2)

    assert %{proof_result: %{status: :checked, proof: %Term.EqRec{}, capability: capability}} =
             Proof.attach(env, step)

    assert capability.reason == :eq_rec_proof_congruence
  end

  test "EqRec base rewrite steps report explicit base boundary" do
    {:ok, env} = Prelude.env()
    zero = Term.const(:zero)
    nat = Term.const(:Nat)
    motive = Term.lam(:n, nat, Term.shift(nat, 1))
    eq_rec = Term.eq_rec(nat, motive, zero, Term.refl(zero))
    equality = Term.eq(nat, zero, zero)
    rule = Rule.new(:same_zero, equality, proof: Term.refl(zero))

    assert {:ok, step} = Rewrite.once_with_step(eq_rec, rule)
    assert step.path == [:base]

    assert %{proof_result: %{status: :checked, capability: %{reason: :eq_rec_base_congruence}}} =
             Proof.attach(env, step)
  end

  test "EqRec base rewrite steps can carry checked non-definitional proof" do
    {:ok, env} = Prelude.env()
    zero = Term.const(:zero)
    one = Term.app(Term.const(:succ), zero)
    nat = Term.const(:Nat)
    motive = Term.lam(:n, nat, Term.shift(nat, 1))
    eq_rec = Term.eq_rec(nat, motive, zero, Term.refl(zero))
    equality = Term.eq(nat, zero, one)

    {:ok, env} = Kernel.add_axiom(env, :zero_eq_one, equality)

    rule = Rule.new(:zero_to_one, equality, proof: Term.const(:zero_eq_one))

    assert {:ok, step} = Rewrite.once_with_step(eq_rec, rule)
    assert step.path == [:base]
    assert step.after == Term.eq_rec(nat, motive, one, Term.refl(zero))

    assert %{proof_result: %{status: :checked, proof: %Term.EqRec{}, capability: capability}} =
             Proof.attach(env, step)

    assert capability.reason == :eq_rec_base_congruence
  end

  test "nested EqRec base rewrite steps can carry checked proof" do
    {:ok, env} = Prelude.env()
    zero = Term.const(:zero)
    one = Term.app(Term.const(:succ), zero)
    succ = Term.const(:succ)
    nat = Term.const(:Nat)
    motive = Term.lam(:n, nat, Term.shift(nat, 1))
    base = Term.app(succ, zero)
    eq_rec = Term.eq_rec(nat, motive, base, Term.refl(zero))
    equality = Term.eq(nat, zero, one)

    {:ok, env} = Kernel.add_axiom(env, :zero_eq_one, equality)

    rule = Rule.new(:zero_to_one, equality, proof: Term.const(:zero_eq_one))

    assert {:ok, step} = Rewrite.once_with_step(eq_rec, rule)
    assert step.path == [:base, :arg]
    assert step.after == Term.eq_rec(nat, motive, Term.app(succ, one), Term.refl(zero))

    assert %{proof_result: %{status: :checked, proof: %Term.EqRec{}, capability: capability}} =
             Proof.attach(env, step)

    assert capability.reason == :eq_rec_base_congruence
    assert capability.inner.reason == :application_congruence
  end

  test "let value rewrite steps can carry checked proof" do
    {:ok, env} = Prelude.env()
    zero = Term.const(:zero)
    one = Term.app(Term.const(:succ), zero)
    nat = Term.const(:Nat)
    equality = Term.eq(nat, zero, one)

    {:ok, env} = Kernel.add_axiom(env, :zero_eq_one, equality)

    term = Term.let(:x, nat, zero, Term.bvar(0))
    rule = Rule.new(:zero_to_one, equality, proof: Term.const(:zero_eq_one))

    assert {:ok, step} = Rewrite.once_with_step(term, rule)
    assert step.path == [:value]
    assert step.after == Term.let(:x, nat, one, Term.bvar(0))

    assert %{proof_result: %{status: :checked, proof: %Term.EqRec{}, capability: capability}} =
             Proof.attach(env, step)

    assert capability.reason == :value_congruence
  end

  test "binder rewrite steps report unsupported proof lifting" do
    {:ok, env} = Prelude.env()
    zero = Term.const(:zero)
    one = Term.app(Term.const(:succ), zero)
    equality = Term.eq(Term.const(:Nat), zero, one)
    rule = Rule.new(:zero_to_one, equality, proof: Term.refl(zero))
    term = Term.lam(:x, Term.const(:Nat), zero)

    assert {:ok, step} = Rewrite.once_with_step(term, rule)
    assert step.path == [:body]
    assert %{proof_result: %{status: :kernel_rejected}} = Proof.attach(env, step)
  end

  test "nested application rewrite steps can carry checked proof" do
    {:ok, env} = Prelude.env()
    zero = Term.const(:zero)
    succ = Term.const(:succ)
    equality = Term.eq(Term.const(:Nat), zero, zero)
    rule = Rule.new(:same_zero, equality, proof: Term.refl(zero))
    term = Term.app(succ, Term.app(succ, zero))

    assert {:ok, step} = Rewrite.once_with_step(term, rule)
    assert step.path == [:arg, :arg]
    assert %Term.EqRec{} = Proof.for_step(env, step)
  end

  test "function-position rewrite steps can carry checked proof" do
    {:ok, env} = Prelude.env()
    bool_not = Term.const(:bool_not)
    bool = Term.const(:Bool)
    fun_type = Term.arrow(bool, bool)
    equality = Term.eq(fun_type, bool_not, bool_not)
    rule = Rule.new(:same_bool_not, equality, proof: Term.refl(bool_not))
    term = Term.app(bool_not, Term.const(true))

    assert {:ok, step} = Rewrite.once_with_step(term, rule)
    assert step.path == [:fun]
    assert %Term.EqRec{} = Proof.for_step(env, step)
  end

  test "database applies the first matching equation rule" do
    lemma = Lemma.new(:zero_to_one, Term.const(:zero), Term.const(:one))
    rule = Rule.from_lemma(lemma, Term.const(:Nat))
    database = Database.from_lemmas([lemma], Term.const(:Nat))
    term = Term.app(Term.const(:succ), Term.const(:zero))

    assert Database.once(database, term) ==
             {:ok, Term.app(Term.const(:succ), Term.const(:one)), rule}
  end

  test "database builds rules from generated environment equations" do
    {:ok, env} = Prelude.env()
    database = Database.from_env_equations(env)

    bool_false = Term.const(false)

    assert {:ok, ^bool_false,
            %Rule{name: %Identity{kind: :equation, owner: :bool_not, target: true}}} =
             Database.once(database, Term.app(Term.const(:bool_not), Term.const(true)))

    singleton = list_cons(nat(), zero(), list_nil())

    append_nil =
      list_constant(:list_append)
      |> Term.app(nat())
      |> Term.app(list_nil())
      |> Term.app(singleton)

    assert {:ok, ^singleton,
            %Rule{name: %Identity{kind: :equation, owner: :list_append, target: nil}}} =
             Database.once(database, append_nil)

    one = Term.app(Term.const(:succ), zero())
    add_zero = Term.const(:nat_add) |> Term.app(zero()) |> Term.app(one)

    assert {:ok, ^one, %Rule{name: %Identity{kind: :equation, owner: :nat_add, target: :zero}}} =
             Database.once(database, add_zero)
  end

  test "rewrite steps record schematic substitutions" do
    {:ok, env} = Prelude.env()
    database = Database.from_env_equations(env, realize: true)
    one = Term.app(Term.const(:succ), zero())
    add_zero = Term.const(:nat_add) |> Term.app(zero()) |> Term.app(one)

    assert {:ok,
            %Theoria.Rewrite.Step{
              path: [],
              substitution: %{0 => ^one},
              proof_result: %{proof: proof}
            }} =
             Database.once_with_step(database, add_zero)

    assert %Term.App{} = proof
  end

  test "database lazily realizes selected equation rules" do
    {:ok, env} = Prelude.env()
    database = Database.from_env_equations(env, realize: :lazy)

    one = Term.app(Term.const(:succ), zero())
    add_zero = Term.const(:nat_add) |> Term.app(zero()) |> Term.app(one)

    refute Enum.any?(database.rules, & &1.realized)

    assert {:ok,
            %Theoria.Rewrite.Step{
              rule: %Rule{realized: %Theoria.Equation.Realized{}},
              proof_result: %{proof: %Term.App{}}
            }} =
             Database.once_with_step(database, env, add_zero, realize: :lazy)
  end

  test "database can realize generated equation rules as proof-backed artifacts" do
    {:ok, env} = Prelude.env()
    database = Database.from_env_equations(env, realize: true)

    one = Term.app(Term.const(:succ), zero())
    add_zero = Term.const(:nat_add) |> Term.app(zero()) |> Term.app(one)

    assert {:ok, ^one, %Rule{proof: %Term.Lam{}, realized: %Theoria.Equation.Realized{}}} =
             Database.once(database, add_zero)
  end

  test "database can realize generated matcher equations as proof-backed artifacts" do
    {:ok, env} = Prelude.env()
    database = Database.from_env_all_equations(env, realize: true)
    matcher_equation = Identity.matcher_equation(:bool_not_match_1, true)

    assert {:ok, rewritten,
            %Rule{name: ^matcher_equation, proof: %Term.Refl{}, realized: realized}} =
             Database.once(database, Term.app(Term.const(:bool_not), Term.const(true)))

    assert rewritten == Term.const(false)
    assert %Theoria.Equation.Realized{identity: ^matcher_equation} = realized
  end

  test "database can include generated matcher equations without indexed metadata" do
    {:ok, env} = Prelude.env()
    database = Database.from_env_all_equations(env)

    matcher_equation = Identity.matcher_equation(:bool_not_match_1, true)

    assert Enum.any?(database.rules, &(&1.name == matcher_equation))

    refute Enum.any?(
             database.rules,
             &match?(%{name: %Identity{kind: :indexed_matcher_equation}}, &1)
           )

    assert {:ok, rewritten, %Rule{name: ^matcher_equation}} =
             Database.once(database, Term.app(Term.const(:bool_not), Term.const(true)))

    assert rewritten == Term.const(false)
  end

  defp nat, do: Term.const(:Nat)
  defp zero, do: Term.const(:zero)
  defp list_nil, do: Term.app(list_constant(:list_nil), nat())

  defp list_cons(type, head, tail) do
    list_constant(:list_cons)
    |> Term.app(type)
    |> Term.app(head)
    |> Term.app(tail)
  end

  defp list_constant(name), do: Term.const(name, [1])
end
