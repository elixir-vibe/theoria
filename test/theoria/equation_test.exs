defmodule Theoria.EquationTest do
  use ExUnit.Case, async: true

  alias Theoria.Env.RecursorRule
  alias Theoria.Equation

  alias Theoria.Equation.{
    Branch,
    CaseTemplate,
    Clause,
    Context,
    Eqns,
    FixedParams,
    Info,
    Lemma,
    MatcherEqns,
    MatcherInfo,
    MatcherType,
    Pattern,
    Schema,
    SchemaBuilder,
    Signature
  }

  alias Theoria.Equation.MatcherInfo.Alternative
  alias Theoria.Library.Nat
  alias Theoria.Prelude
  alias Theoria.Term

  test "equation info records Lean-like definition metadata" do
    info = Info.new(:f, nat(), zero(), rec_arg_pos: 0, fixed_params: FixedParams.new([1]))

    assert info.name == :f
    assert info.rec_arg_pos == 0
    assert FixedParams.fixed?(info.fixed_params, 1)
    refute FixedParams.fixed?(info.fixed_params, 0)

    {:ok, env} = Nat.env()
    assert {:ok, info} = Info.from_env(env, :nat_add, rec_arg_pos: 0)
    assert info.name == :nat_add
    assert info.rec_arg_pos == 0
    assert info.level_params == []
    assert {:ok, %Info{name: :nat_add, rec_arg_pos: 0}} = Info.fetch(env, :nat_add)
    assert {:ok, %Info{name: :nat_add, rec_arg_pos: 0}} = Info.fetch_or_build(env, :nat_add)
    assert Info.equation?(env, :nat_add)
    refute Info.equation?(env, :Nat)
    assert Enum.map(Info.all(env), & &1.name) == [:nat_add]
    assert {:error, {:missing_value, :Nat}} = Info.fetch_or_build(env, :Nat)
  end

  test "schema builder generates schemas and matcher metadata from signatures" do
    signature = Signature.new(:plus, :nat, [{:m, nat()}, {:n, nat()}], nat(), rec_arg_pos: 0)
    n = Term.bvar(0)

    assert {:ok, schema} =
             SchemaBuilder.build(signature, [
               CaseTemplate.new(:zero, Term.const(:plus) |> Term.app(zero()) |> Term.app(n), n,
                 binders: [{:n, nat()}]
               )
             ])

    assert schema.family == :nat
    assert Enum.map(schema.equations, & &1.suffix) == [:zero]
    assert SchemaBuilder.matcher(signature, schema).name == :"plus.match_1"
  end

  test "schema validates scope and duplicate equation suffixes" do
    valid =
      Schema.new(:nat, [
        Schema.equation(:zero, zero(), zero(), nat())
      ])

    assert :ok = Schema.validate(valid)

    duplicate =
      Schema.new(:nat, [
        Schema.equation(:zero, zero(), zero(), nat()),
        Schema.equation(:zero, zero(), zero(), nat())
      ])

    assert {:error, :duplicate_equation_suffix} = Schema.validate(duplicate)
    assert SchemaBuilder.overlaps(duplicate) == %{0 => [1]}
  end

  test "matcher info records small Lean-like matcher metadata" do
    alt = %Alternative{constructor: :zero, num_fields: 0}
    info = MatcherInfo.new(:match_nat, 0, 1, [alt])

    assert MatcherInfo.arity(info) == 3
  end

  test "matcher type builds real Bool, Nat, and List matcher shapes" do
    {:ok, env} = Prelude.env()
    {:ok, bool_info} = Info.fetch(env, :bool_not)
    {:ok, nat_info} = Info.fetch(env, :nat_add)
    {:ok, list_info} = Info.fetch(env, :list_append)

    assert {:ok, bool_type} = MatcherType.build(bool_info.schema, bool_info.matcher)

    assert %Term.Forall{
             name: :motive,
             body: %Term.Forall{
               name: :b,
               body: %Term.Forall{name: :on_true, body: %Term.Forall{name: :on_false}}
             }
           } = bool_type

    assert [_true_alt, _false_alt] = MatcherType.alternatives(bool_info.schema, bool_info.matcher)
    assert {:ok, nat_type} = MatcherType.build(nat_info.schema, nat_info.matcher)

    assert %Term.Forall{
             name: :motive,
             body: %Term.Forall{
               name: :n,
               body: %Term.Forall{name: :on_zero, body: %Term.Forall{name: :on_succ}}
             }
           } = nat_type

    assert [
             _zero_alt,
             %MatcherType.Alternative{
               constructor: :succ,
               fields: [{:pred, %Term.Const{name: :Nat}}]
             }
           ] =
             MatcherType.alternatives(nat_info.schema, nat_info.matcher)

    assert {:ok, list_type} = MatcherType.build(list_info.schema, list_info.matcher)

    assert %Term.Forall{
             name: :a,
             body: %Term.Forall{
               name: :motive,
               body: %Term.Forall{name: :xs, body: %Term.Forall{name: :on_nil}}
             }
           } = list_type

    assert [
             _nil_alt,
             %MatcherType.Alternative{
               constructor: :list_cons,
               fields: [{:head, _head}, {:tail, _tail}]
             }
           ] = MatcherType.alternatives(list_info.schema, list_info.matcher)
  end

  test "fixed params derive from signature parameters" do
    signature =
      Signature.new(:list_length, :list, [{:xs, Term.const(:List)}], nat(),
        rec_arg_pos: 0,
        parameters: [{:a, Term.sort(1)}]
      )

    assert signature.fixed_params.positions == [0]
    assert {:ok, fixed_params} = FixedParams.analyze(signature)
    assert fixed_params.positions == [0]
  end

  test "equation lemma metadata becomes defeq checks and checked theorems" do
    info = Info.new(:nat_add, nat(), zero())
    assert Lemma.theorem_name(:nat_add, :zero) == :"nat_add.eq_zero"
    lemma = Lemma.for_definition(info, :zero, zero(), zero())
    check = Lemma.defeq_check(lemma, :nat)

    assert check.name == "nat_add.eq_zero"
    assert check.category == :nat
    assert check.left == zero()
    assert check.right == zero()

    {:ok, env} = Nat.env()
    assert {:ok, theorem} = Lemma.to_theorem(env, lemma, nat())
    assert theorem.type == Term.eq(nat(), zero(), zero())
    assert theorem.proof == Term.refl(zero())

    assert {:ok, env, theorem} = Lemma.add_to_env(env, lemma, nat())
    assert theorem.name == :"nat_add.eq_zero"
    assert {:ok, _constant} = Theoria.Env.fetch(env, :"nat_add.eq_zero")

    other = Lemma.for_definition(info, :zero_again, zero(), zero())
    assert {:ok, env, [installed]} = Lemma.add_all_to_env(env, [other], nat())
    assert installed.name == :"nat_add.eq_zero_again"
    assert {:ok, _constant} = Theoria.Env.fetch(env, :"nat_add.eq_zero_again")
  end

  test "generated equation lemmas come from stored definition metadata" do
    {:ok, env} = Prelude.env()
    {:ok, info} = Info.fetch(env, :nat_add)

    assert Enum.map(Lemma.generated_for(info), & &1.name) == [
             :"nat_add.eq_zero",
             :"nat_add.eq_succ"
           ]

    assert {:ok, env, theorems} = Lemma.add_generated_to_env(env, :nat_add)
    assert Enum.map(theorems, & &1.name) == Enum.map(Lemma.generated_for(info), & &1.name)
    assert {:ok, _constant} = Theoria.Env.fetch(env, :"nat_add.eq_succ")
    assert Eqns.installed?(env, :nat_add)
  end

  test "generated equation lookup mirrors Lean-style getEqnsFor" do
    {:ok, env} = Prelude.env()

    assert {:ok, [:"nat_add.eq_zero", :"nat_add.eq_succ"]} = Eqns.get(env, :nat_add)
    assert {:ok, :nat_add} = Eqns.source(env, :"nat_add.eq_succ")
    assert {:ok, :nat_add} = Eqns.source(env, :"nat_add.eq_def")
    assert {:ok, :nat_add} = Eqns.source(env, :"nat_add.match_1.eq_succ")
    assert {:ok, :"nat_add.match_1"} = MatcherEqns.source(env, :"nat_add.match_1.eq_succ")
    assert {:ok, [zero_theorem, succ_theorem]} = Eqns.realize(env, :nat_add)
    assert zero_theorem.name == :"nat_add.eq_zero"
    assert succ_theorem.name == :"nat_add.eq_succ"
    assert {:ok, theorem} = Eqns.realize(env, :"nat_add.eq_succ")
    assert theorem.name == :"nat_add.eq_succ"
    assert {:ok, unfold} = Eqns.unfold(env, :nat_add)
    assert unfold.name == :"nat_add.eq_def"
    assert {:ok, _theorem} = Lemma.to_theorem(env, unfold)
    assert {:ok, lemmas} = Eqns.generated(env, :list_append)
    assert Enum.map(lemmas, & &1.name) == [:"list_append.eq_nil", :"list_append.eq_cons"]
    refute Eqns.installed?(env, :nat_add)
  end

  test "schematic generated equation lemmas become forall theorems" do
    {:ok, env} = Prelude.env()
    {:ok, [_, succ_lemma]} = Eqns.generated(env, :nat_add)

    assert succ_lemma.binders == [{:m, nat()}, {:n, nat()}]
    assert {:ok, theorem} = Lemma.to_theorem(env, succ_lemma)
    assert %Term.Forall{name: :m, body: %Term.Forall{name: :n}} = theorem.type
  end

  test "Bool, Nat, and List matchers are checked real matcher declarations" do
    {:ok, env} = Prelude.env()

    for {definition, matcher_name} <- [
          bool_not: :"bool_not.match_1",
          nat_add: :"nat_add.match_1",
          list_length: :"list_length.match_1",
          list_append: :"list_append.match_1"
        ] do
      {:ok, info} = Info.fetch(env, definition)
      {:ok, matcher} = Theoria.Env.fetch_matcher(env, matcher_name)

      assert matcher.mode == :matcher
      assert matcher.type != info.type
      assert matcher.value != info.value
    end

    assert {:ok, _env} = Theoria.Kernel.validate_env(env)
  end

  test "stored equation metadata includes clauses and matcher alternatives" do
    {:ok, env} = Prelude.env()
    {:ok, info} = Info.fetch(env, :list_append)

    assert length(info.clauses) == 2
    assert info.matcher.name == :"list_append.match_1"
    assert length(info.matcher.discriminants) == 1
    assert [%{name: :ys, position: 1, family: :list}] = info.matcher.discriminants
    assert info.matcher.overlaps == %{}
    assert info.schema.family == :list
    assert Enum.map(info.schema.equations, & &1.suffix) == [nil, :cons]
    assert Enum.map(info.matcher.alternatives, & &1.constructor) == [:list_nil, :list_cons]
    assert {:ok, matcher} = Theoria.Env.fetch_matcher(env, :"list_append.match_1")
    assert matcher.source == :list_append

    assert matcher.equation_names == [
             :"list_append.match_1.eq_list_nil",
             :"list_append.match_1.eq_list_cons"
           ]
  end

  test "matcher equations are generated from matcher metadata" do
    {:ok, env} = Prelude.env()
    {:ok, names} = MatcherEqns.get(env, :"list_append.match_1")

    assert names == [:"list_append.match_1.eq_list_nil", :"list_append.match_1.eq_list_cons"]

    [nil_equation | _rest] =
      MatcherEqns.all(env) |> Enum.filter(&(&1.matcher == :"list_append.match_1"))

    assert nil_equation.constructor == :list_nil
    assert {:ok, equations} = MatcherEqns.generated(env, :"list_append.match_1")
    assert Enum.map(equations, & &1.name) == names
    assert {:ok, theorem} = MatcherEqns.realize(env, :"list_append.match_1.eq_list_nil")
    assert theorem.name == :"list_append.match_1.eq_list_nil"
  end

  test "environment replay rejects corrupted matcher declarations" do
    {:ok, env} = Prelude.env()
    {:ok, constant} = Theoria.Env.fetch(env, :"nat_add.match_1")
    corrupted = %{constant | value: Term.const(:zero)}
    env = %{env | constants: Map.put(env.constants, :"nat_add.match_1", corrupted)}

    assert {:error, error} = Theoria.Kernel.validate_env(env)
    assert error.reason in [:type_mismatch, :invalid_declaration]
  end

  test "library and compiler modules do not hand-author definition-specific schema helpers" do
    forbidden_helpers =
      ~w(bool_schema nat_add_schema schema_for bool_matcher nat_matcher list_matcher)

    for path <- [
          "lib/theoria/library/bool.ex",
          "lib/theoria/library/nat.ex",
          "lib/theoria/library/list.ex"
        ],
        helper <- forbidden_helpers do
      refute File.read!(path) =~ "defp #{helper}"
    end

    compiler = File.read!("lib/theoria/equation/compiler.ex")

    for name <- ~w(bool_not bool_and bool_or nat_add list_length list_append) do
      refute compiler =~ name
    end
  end

  test "equation lookup installs all generated theorems and builds rules" do
    {:ok, env} = Prelude.env()

    assert {:ok, rules} = Eqns.rules(env, :nat_add)
    assert Enum.map(rules, & &1.name) == [:"nat_add.eq_zero", :"nat_add.eq_succ"]

    assert {:ok, env, theorems} = Eqns.install_all(env)
    assert length(theorems) == 16
    assert Eqns.installed?(env, :list_append)
  end

  test "generated equation lemmas cover supported compiled definitions" do
    {:ok, env} = Prelude.env()

    generated =
      env
      |> Info.all()
      |> Map.new(&{&1.name, Enum.map(Lemma.generated_for(&1), fn lemma -> lemma.name end)})

    assert generated.bool_not == [:"bool_not.eq_true", :"bool_not.eq_false"]
    assert :"bool_and.eq_true_false" in generated.bool_and
    assert :"bool_or.eq_false_true" in generated.bool_or
    assert generated.nat_add == [:"nat_add.eq_zero", :"nat_add.eq_succ"]
    assert generated.list_length == [:"list_length.eq_nil", :"list_length.eq_cons"]
    assert generated.list_append == [:"list_append.eq_nil", :"list_append.eq_cons"]
  end

  test "context exposes branch and outer values" do
    context = Context.new(%{ih: Term.bvar(0), x: Term.bvar(2)}, %{a: nat()})

    assert context.ih == Term.bvar(0)
    assert context.x == Term.bvar(2)
    assert context.a == nat()
    assert Context.var!(context, :ih) == Term.bvar(0)
    assert Context.outer!(context, :a) == nat()
    assert Context.fetch!(context, :x) == Term.bvar(2)
  end

  test "branch descriptors expose generated binders and contexts" do
    nat_clause = Clause.new([Pattern.constructor(:succ, [Pattern.var(:n)])], fn ctx -> ctx.ih end)
    nat_branch = Branch.nat_succ(nat_clause)

    assert Enum.map(nat_branch.binders, &elem(&1, 0)) == [:n, :ih]
    assert nat_branch.context.n == Term.bvar(1)
    assert nat_branch.context.ih == Term.bvar(0)

    list_clause =
      Clause.new([Pattern.constructor(:list_cons, [Pattern.var(:x), Pattern.var(:xs)])], fn ctx ->
        ctx.ih
      end)

    list_branch = Branch.list_cons(list_clause, nat(), nat_list())

    assert Enum.map(list_branch.binders, &elem(&1, 0)) == [:x, :xs, :ih]
    assert list_branch.context.x == Term.bvar(2)
    assert list_branch.context.xs == Term.bvar(1)
    assert list_branch.context.ih == Term.bvar(0)
    assert list_branch.context.a == Term.shift(nat(), 3)

    rule = %RecursorRule{constructor: :succ, field_count: 1, rhs: Term.bvar(0)}
    generic = Branch.from_recursor_rule(nat_clause, rule, [nat()])

    assert Enum.map(generic.binders, &elem(&1, 0)) == [:n]
    assert generic.context.n == Term.bvar(0)
  end

  test "vec branch descriptor records indexed metadata context" do
    clause =
      Clause.new(
        [
          Pattern.constructor(:vec_cons, [Pattern.var(:n), Pattern.var(:head), Pattern.var(:tail)])
        ],
        fn ctx -> ctx.ih end
      )

    branch = Branch.vec_cons(clause, nat(), Term.bvar(0), nat_list())

    assert Enum.map(branch.binders, &elem(&1, 0)) == [:n, :head, :tail, :ih]
    assert branch.context.n == Term.bvar(3)
    assert branch.context.head == Term.bvar(2)
    assert branch.context.tail == Term.bvar(1)
    assert branch.context.ih == Term.bvar(0)
    assert branch.context.length == Term.shift(Term.bvar(0), 4)
  end

  test "builds Bool recursor applications" do
    term =
      Equation.bool_rec(Term.const(:Bool), Term.const(false), Term.const(true), Term.const(true))

    assert {%Term.Const{name: :bool_rec}, args} = Term.Application.collect(term)
    assert args == [Term.const(:Bool), Term.const(false), Term.const(true), Term.const(true)]
  end

  test "generic compiler dispatches supported fragments" do
    assert {:ok, term} =
             Equation.compile(
               :bool,
               Term.const(:Bool),
               [
                 Clause.new([Pattern.constructor(true)], Term.const(false)),
                 Clause.new([Pattern.constructor(false)], Term.const(true))
               ],
               Term.const(true)
             )

    assert {%Term.Const{name: :bool_rec}, _args} = Term.Application.collect(term)

    assert {:ok, term} =
             Equation.compile(
               :nat,
               nat(),
               [
                 Clause.new([Pattern.constructor(:zero)], zero()),
                 Clause.new([Pattern.constructor(:succ, [Pattern.var(:n)])], fn ctx -> ctx.ih end)
               ],
               zero()
             )

    assert {%Term.Const{name: :nat_rec}, _args} = Term.Application.collect(term)

    assert {:ok, term} =
             Equation.compile(
               {:list, nat(), [1, 1]},
               nat_list(),
               [
                 Clause.new([Pattern.constructor(:list_nil)], Term.const(:list_nil)),
                 Clause.new(
                   [Pattern.constructor(:list_cons, [Pattern.var(:x), Pattern.var(:xs)])],
                   fn ctx -> ctx.ih end
                 )
               ],
               Term.const(:xs)
             )

    assert {%Term.Const{name: :list_rec}, _args} = Term.Application.collect(term)
  end

  test "compiles Bool constructor clauses" do
    assert {:ok, term} =
             Equation.compile_bool(
               Term.const(:Bool),
               [
                 Clause.new([Pattern.constructor(true)], Term.const(false)),
                 Clause.new([Pattern.constructor(false)], Term.const(true))
               ],
               Term.const(true)
             )

    assert {%Term.Const{name: :bool_rec}, args} = Term.Application.collect(term)
    assert args == [Term.const(:Bool), Term.const(false), Term.const(true), Term.const(true)]
  end

  test "validates Bool constructor clauses" do
    assert {:error, {:missing_clause, missing}} =
             Equation.compile_bool(Term.const(:Bool), [], Term.const(true))

    assert missing in [true, false]

    assert Equation.compile_bool(
             Term.const(:Bool),
             [
               Clause.new([Pattern.constructor(true)], Term.const(true)),
               Clause.new([Pattern.constructor(true)], Term.const(false)),
               Clause.new([Pattern.constructor(false)], Term.const(false))
             ],
             Term.const(true)
           ) == {:error, {:duplicate_clause, true}}

    assert Equation.compile_bool(
             Term.const(:Bool),
             [
               Clause.new([Pattern.constructor(:foo)], Term.const(true)),
               Clause.new([Pattern.constructor(false)], Term.const(false))
             ],
             Term.const(true)
           ) == {:error, {:unexpected_clause, :foo}}
  end

  test "builds Nat recursor applications" do
    succ_case = nat_lam(:n, Term.bvar(0))
    term = Equation.nat_rec(nat(), zero(), succ_case, zero())

    assert {%Term.Const{name: :nat_rec}, args} = Term.Application.collect(term)
    assert args == [nat(), zero(), succ_case, zero()]
  end

  test "validates recursive pattern shape" do
    assert Equation.compile_nat(
             Term.const(:Nat),
             [
               Clause.new([Pattern.constructor(:zero)], Term.const(:zero)),
               Clause.new([Pattern.constructor(:succ)], Term.const(:zero))
             ],
             Term.const(:zero)
           ) == {:error, {:constructor_arity_mismatch, :succ, [expected: 1, actual: 0]}}

    assert Equation.compile_list(
             Term.const(:Nat),
             nat_list(),
             [
               Clause.new([Pattern.constructor(:list_nil)], Term.const(:list_nil)),
               Clause.new(
                 [Pattern.constructor(:list_cons, [Pattern.var(:x), Pattern.var(:x)])],
                 Term.const(:list_nil)
               )
             ],
             Term.const(:xs)
           ) == {:error, {:duplicate_pattern_variable, :x}}

    assert Equation.compile_nat(
             Term.const(:Nat),
             [
               Clause.new([Pattern.constructor(:zero)], Term.const(:zero)),
               Clause.new([Pattern.constructor(:succ, [:n])], Term.const(:zero))
             ],
             Term.const(:zero)
           ) == {:error, {:invalid_pattern, :n}}
  end

  test "compiles Nat constructor clauses" do
    succ_case = nat_lam(:n, Term.bvar(0))

    assert {:ok, term} =
             Equation.compile_nat(
               Term.const(:Nat),
               [
                 Clause.new([Pattern.constructor(:zero)], Term.const(:zero)),
                 Clause.new([Pattern.constructor(:succ, [Pattern.var(:n)])], succ_case)
               ],
               Term.const(:zero)
             )

    assert {%Term.Const{name: :nat_rec}, args} = Term.Application.collect(term)
    assert args == [nat(), zero(), succ_case, zero()]
  end

  test "materializes Nat succ branches from non-lambda bodies" do
    assert {:ok, term} =
             Equation.compile_nat(
               Term.const(:Nat),
               [
                 Clause.new([Pattern.constructor(:zero)], Term.const(:zero)),
                 Clause.new([Pattern.constructor(:succ, [Pattern.var(:n)])], fn ctx -> ctx.ih end)
               ],
               Term.const(:zero)
             )

    assert {%Term.Const{name: :nat_rec}, [_motive, _zero, succ_case, _major]} =
             Term.Application.collect(term)

    assert_lams(succ_case, [:n, :ih], Term.bvar(0))
  end

  test "builds List recursor applications" do
    list = nat_list()
    cons_case = nat_lam(:x, Term.bvar(0))

    term =
      Equation.list_rec(nat(), list, Term.const(:list_nil), cons_case, Term.const(:xs))

    assert {%Term.Const{name: :list_rec}, args} = Term.Application.collect(term)
    assert args == [nat(), list, Term.const(:list_nil), cons_case, Term.const(:xs)]
  end

  test "compiles List constructor clauses" do
    list = nat_list()
    cons_case = nat_lam(:x, Term.bvar(0))

    assert {:ok, term} =
             Equation.compile_list(
               Term.const(:Nat),
               list,
               [
                 Clause.new([Pattern.constructor(:list_nil)], Term.const(:list_nil)),
                 Clause.new(
                   [Pattern.constructor(:list_cons, [Pattern.var(:x), Pattern.var(:xs)])],
                   cons_case
                 )
               ],
               Term.const(:xs)
             )

    assert {%Term.Const{name: :list_rec}, args} = Term.Application.collect(term)
    assert args == [nat(), list, Term.const(:list_nil), cons_case, Term.const(:xs)]
  end

  test "materializes List cons branches from non-lambda bodies" do
    list = nat_list()

    assert {:ok, term} =
             Equation.compile_list(
               Term.const(:Nat),
               list,
               [
                 Clause.new([Pattern.constructor(:list_nil)], Term.const(:list_nil)),
                 Clause.new(
                   [Pattern.constructor(:list_cons, [Pattern.var(:x), Pattern.var(:xs)])],
                   fn ctx -> ctx.ih end
                 )
               ],
               Term.const(:xs)
             )

    assert {%Term.Const{name: :list_rec}, [_element_type, _motive, _nil, cons_case, _major]} =
             Term.Application.collect(term)

    assert_lams(cons_case, [:x, :xs, :ih], Term.bvar(0))
  end

  defp nat, do: Term.const(:Nat)
  defp zero, do: Term.const(:zero)
  defp nat_list, do: Term.app(Term.const(:List), nat())
  defp nat_lam(name, body), do: Term.lam(name, nat(), body)

  defp assert_lams(term, names, body) do
    assert collect_lams(term) == {names, body}
  end

  defp collect_lams(%Term.Lam{name: name, body: body}) do
    {names, body} = collect_lams(body)
    {[name | names], body}
  end

  defp collect_lams(body), do: {[], body}
end
