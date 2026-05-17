defmodule Theoria.PrettyTest do
  use ExUnit.Case, async: true

  alias Theoria.Env.Matcher, as: EnvMatcher

  alias Theoria.Equation.{
    CaseTemplate,
    FixedParams,
    Info,
    Lemma,
    MatcherEquation,
    MatcherInfo,
    Schema,
    Signature
  }

  alias Theoria.Equation.MatcherInfo.Alternative
  alias Theoria.Kernel
  alias Theoria.Level
  alias Theoria.Library.Logic
  alias Theoria.Library.Logic.Theorems
  alias Theoria.Rewrite.{Database, Rule}

  import Theoria.Term

  test "inspects universes" do
    assert inspect(sort(0)) == "#Theoria<Prop>"
    assert inspect(sort(2)) == "#Theoria<Type 2>"
    assert inspect(sort(Level.param(:u))) == "#Theoria<Sort u>"
    assert inspect(Level.param(:u)) == "#Theoria<level u>"
  end

  test "inspects universe-polymorphic constants" do
    assert inspect(const(:List, [1])) == "#Theoria<List.1>"
    assert inspect(const(:List, [Level.param(:u)])) == "#Theoria<List.u>"
  end

  test "inspects variables with binder names" do
    type = forall(:p, sort(0), arrow(bvar(0), bvar(0)))

    assert inspect(type) == "#Theoria<∀ p : Prop, p → p>"
  end

  test "inspects lambdas" do
    proof = lam(:p, sort(0), lam(:hp, bvar(0), bvar(0)))

    assert inspect(proof) == "#Theoria<λ p : Prop, λ hp : p, hp>"
  end

  test "inspects equality and reflexivity" do
    assert inspect(eq(bvar(1), bvar(0), bvar(0))) == "#Theoria<#0 = #0>"
    assert inspect(refl(bvar(0))) == "#Theoria<refl #0>"

    assert inspect(eq_rec(const(:Nat), const(:motive), const(:base), const(:proof))) ==
             "#Theoria<Eq.rec Nat motive base proof>"
  end

  test "inspects equation and rewrite metadata" do
    info =
      Info.new(:list_append, const(:Nat), const(:zero),
        level_params: [:u],
        rec_arg_pos: 1,
        fixed_params: FixedParams.new([0])
      )

    lemma = Lemma.new(:"list_append.eq_nil", const(:zero), const(:zero))
    alternative = %Alternative{constructor: :list_nil, num_fields: 0}
    matcher = MatcherInfo.new(:match_list, 1, 1, [alternative])
    matcher_equation = MatcherEquation.from_lemma(:match_list, :list_nil, lemma)

    env_matcher =
      EnvMatcher.new(:match_list, :list_append, const(:Nat), matcher,
        equation_names: [:"match_list.eq_list_nil"]
      )

    signature = Signature.new(:list_append, :list, [m: const(:Nat)], const(:Nat), rec_arg_pos: 0)
    template = CaseTemplate.new(:list_nil, const(:zero), const(:zero))
    schema = Schema.new(:list, [Schema.equation(nil, const(:zero), const(:zero), const(:Nat))])
    rule = Rule.from_lemma(lemma, const(:Nat))
    database = Database.new([rule])

    assert inspect(info) ==
             "#Theoria.EquationInfo<list_append, rec_arg: 1, fixed: [0], levels: [:u]>"

    assert inspect(info.fixed_params) == "#Theoria.FixedParams<[0]>"
    assert inspect(lemma) == "#Theoria.EquationLemma<list_append.eq_nil>"
    assert inspect(alternative) == "#Theoria.MatcherAlt<list_nil, fields: 0>"

    assert inspect(matcher.discriminants) ==
             "[#Theoria.MatcherDiscriminant<:anonymous, position: nil, family: nil>]"

    assert inspect(matcher) == "#Theoria.MatcherInfo<match_list, discrs: 1, alts: 1>"

    assert inspect(matcher_equation) ==
             "#Theoria.MatcherEquation<match_list.eq_list_nil, matcher: match_list, constructor: :list_nil>"

    assert inspect(env_matcher) ==
             "#Theoria.EnvMatcher<match_list, source: list_append, equations: 1>"

    assert inspect(signature) ==
             "#Theoria.EquationSignature<list_append, family: list, rec_arg: 0>"

    assert inspect(template) == "#Theoria.CaseTemplate<:list_nil, binders: 0>"
    assert inspect(schema) == "#Theoria.EquationSchema<family: list, equations: 1>"
    assert inspect(hd(schema.equations)) == "#Theoria.EquationSchema.Case<nil>"
    assert inspect(rule) == "#Theoria.RewriteRule<list_append.eq_nil forward>"
    assert inspect(database) == "#Theoria.RewriteDatabase<1 rule(s)>"
  end

  test "inspects checked theorems" do
    {:ok, env} = Logic.env()
    {:ok, theorem} = Theorems.identity_theorem(env)

    assert inspect(theorem) == "#Theoria<theorem identity : ∀ p : Prop, p → p>"
  end

  test "inspects trust reports" do
    {:ok, env} = Logic.env()
    {:ok, env} = Kernel.add_axiom(env, :assumed_truth, const(:True))
    {:ok, env} = Kernel.add_theorem(env, :truth, const(:True), const(:assumed_truth))
    {:ok, report} = Kernel.trust_report(env, :truth)

    assert inspect(report) ==
             "#Theoria<trust truth : theorem, axioms: assumed_truth, deps: True, assumed_truth>"
  end
end
