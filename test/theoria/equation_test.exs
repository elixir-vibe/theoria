defmodule Theoria.EquationTest do
  use ExUnit.Case, async: true

  alias Theoria.Env.RecursorRule
  alias Theoria.Equation
  alias Theoria.Equation.Case.Template, as: CaseTemplate
  alias Theoria.Equation.Matcher.Descriptor, as: MatcherDescriptor
  alias Theoria.Equation.Matcher.Eqns, as: MatcherEqns
  alias Theoria.Equation.Matcher.Info, as: MatcherInfo
  alias Theoria.Equation.Matcher.Type, as: MatcherType
  alias Theoria.Equation.Recursor.Descriptor, as: RecursorDescriptor
  alias Theoria.Equation.Schema.Builder, as: SchemaBuilder
  alias Theoria.Term.Application, as: TermApplication

  alias Theoria.Equation.{
    Branch,
    Clause,
    Context,
    Eqns,
    Extension,
    FixedParams,
    Info,
    Lemma,
    Pattern,
    Schema,
    Signature
  }

  alias Theoria.Equation.Matcher.Info.Alternative
  alias Theoria.Kernel
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

  test "extension registry indexes generated equations and matchers" do
    {:ok, env} = Prelude.env()
    registry = Extension.build(env)

    assert Map.has_key?(registry.definitions, :nat_add)
    assert Map.has_key?(registry.matchers, :"bool_and.match_1")

    assert registry.equation_names.bool_and == [
             :"bool_and.eq_true_true",
             :"bool_and.eq_true_false",
             :"bool_and.eq_false_true",
             :"bool_and.eq_false_false"
           ]

    assert registry.matcher_equation_names[:"bool_and.match_1"] == [
             :"bool_and.match_1.eq_true_true",
             :"bool_and.match_1.eq_true_false",
             :"bool_and.match_1.eq_false_true",
             :"bool_and.match_1.eq_false_false"
           ]

    assert Extension.source_for(registry, :"bool_and.match_1.eq_false_false") ==
             {:ok, :"bool_and.match_1"}

    assert Extension.unfold_name(env, :nat_add) == {:ok, :"nat_add.eq_def"}

    assert Extension.summary(registry) == %{
             definitions: 6,
             matchers: 6,
             ordinary_equations: 16,
             matcher_equations: 16,
             unfolds: 6,
             theorems: 38
           }

    assert :ok = Extension.validate(env)
    assert {:ok, [matcher]} = {:ok, Extension.matchers_for(env, :nat_add)}
    assert matcher.name == :"nat_add.match_1"
    assert :"bool_and.match_1.eq_true_true" in Extension.theorem_names(registry)
    assert Extension.realizable?(env, :"bool_and.match_1.eq_true_true")
    assert {:ok, theorem} = Extension.realize(env, :"bool_and.match_1.eq_true_true")
    assert theorem.name == :"bool_and.match_1.eq_true_true"
    assert {:ok, theorems} = Extension.realize_all(env)
    assert length(theorems) == map_size(registry.theorem_sources)
  end

  test "extension validation rejects stale matcher equation names" do
    {:ok, env} = Prelude.env()
    env = corrupt_matcher(env, :"bool_and.match_1", &%{&1 | equation_names: [:stale_equation]})

    assert {:error, {:matcher_equation_name_mismatch, :"bool_and.match_1", _, _}} =
             Extension.validate(env)
  end

  test "extension validation rejects matcher declarations with unknown sources" do
    {:ok, env} = Prelude.env()
    env = corrupt_matcher(env, :"bool_and.match_1", &%{&1 | source: :missing_source})

    assert {:error, {:unknown_matcher_source, :"bool_and.match_1", :missing_source}} =
             Extension.validate(env)
  end

  test "extension realization rejects unknown generated theorems" do
    {:ok, env} = Prelude.env()

    assert Extension.realize(env, :"missing.eq") ==
             {:error, {:unknown_generated_theorem, :"missing.eq"}}
  end

  test "matcher descriptors can be derived from checked recursor metadata" do
    {:ok, env} = Prelude.env()

    for definition <- [:bool_not, :bool_and, :nat_add, :list_append] do
      {:ok, info} = Info.fetch(env, definition)
      assert {:ok, fallback} = MatcherDescriptor.from_schema(info.schema, info.matcher)
      assert {:ok, derived} = MatcherDescriptor.from_env(env, info.schema, info.matcher)
      assert derived.family == fallback.family
      assert derived.recursor == fallback.recursor

      assert Enum.map(derived.alternatives, & &1.name) ==
               Enum.map(fallback.alternatives, & &1.name)
    end
  end

  test "recursor descriptor describes indexed Vec recursor rules" do
    {:ok, env} = Prelude.env()

    vec_schema =
      Schema.new(:Vec, [],
        recursive_argument: 1,
        parameter_binders: [a: Term.sort(1)],
        argument_binders: [n: Term.const(:Nat), xs: Term.const(:Vec)]
      )

    assert {:ok, descriptor} = RecursorDescriptor.from_schema(env, vec_schema)
    assert descriptor.family == :Vec
    assert descriptor.recursor.name == :vec_ind
    assert descriptor.indexed?
    assert descriptor.parameters == [a: Term.sort(1)]
    assert Enum.map(descriptor.indices, &elem(&1, 0)) == [:n]

    assert Enum.map(descriptor.rules, &{&1.constructor, &1.field_count}) == [
             vec_nil: 0,
             vec_cons: 3
           ]

    assert [%Term.Const{name: :zero}] = hd(descriptor.rules).index_patterns
    assert [%Term.App{}] = List.last(descriptor.rules).index_patterns

    cons_rule = List.last(descriptor.rules)

    assert Enum.map(cons_rule.fields, &{&1.name, &1.position, &1.recursive?}) == [
             {:field0, 0, false},
             {:field1, 1, false},
             {:field2, 2, true}
           ]

    assert [%{name: :field2, recursive_indices: [%Term.BVar{index: 0}]}] =
             cons_rule.recursive_fields

    matcher =
      MatcherInfo.new(:vec_match, 1, 1, [
        %Alternative{constructor: :vec_nil, num_fields: 0},
        %Alternative{constructor: :vec_cons, num_fields: 3}
      ])

    assert {:ok, matcher_descriptor} = MatcherDescriptor.from_env(env, vec_schema, matcher)
    assert matcher_descriptor.family == :Vec
    assert matcher_descriptor.indexed?
    assert matcher_descriptor.recursive?
    assert Enum.map(matcher_descriptor.alternatives, & &1.name) == [:vec_nil, :vec_cons]

    vec_cons = List.last(matcher_descriptor.alternatives)
    assert Enum.map(vec_cons.fields, & &1.name) == [:field0, :field1, :field2]
    assert Enum.map(vec_cons.recursive_fields, & &1.name) == [:field2]
    assert [%Term.App{}] = vec_cons.index_patterns

    assert {:ok, matcher_shape} = MatcherType.shape_from_descriptor(matcher_descriptor)
    assert matcher_shape.indexed?
    assert matcher_shape.family == :Vec
    assert matcher_shape.parameters == [a: Term.sort(1)]
    assert Enum.map(matcher_shape.indices, &elem(&1, 0)) == [:n]
    assert Enum.map(matcher_shape.index_binders, &elem(&1, 0)) == [:n]
    assert Enum.map(matcher_shape.motive_binders, &elem(&1, 0)) == [:n, :xs]
    assert matcher_shape.motive_arguments == [Term.bvar(3), Term.bvar(2)]

    assert %Term.App{
             fun: %Term.App{fun: %Term.BVar{index: 4}, arg: %Term.BVar{index: 3}},
             arg: %Term.BVar{index: 2}
           } =
             matcher_shape.motive_result

    assert [
             xs: %Term.App{
               fun: %Term.App{fun: %Term.Const{name: :Vec}, arg: %Term.BVar{index: 2}},
               arg: %Term.BVar{index: 0}
             }
           ] =
             matcher_shape.discriminant_binders

    assert Enum.map(matcher_shape.alternatives, & &1.binder_name) == [:on_vec_nil, :on_vec_cons]
    assert matcher_shape.index_patterns[:vec_nil] == [Term.const(:zero)]
    assert [%Term.App{}] = matcher_shape.index_patterns[:vec_cons]

    assert [vec_nil_shape, vec_cons_shape] = matcher_shape.alternatives
    assert vec_nil_shape.index_patterns == [Term.const(:zero)]

    assert [
             %Term.Const{name: :zero},
             %Term.App{fun: %Term.Const{name: :vec_nil}, arg: %Term.BVar{index: 3}}
           ] = vec_nil_shape.motive_arguments

    assert %Term.App{
             fun: %Term.App{fun: %Term.BVar{index: 2}, arg: %Term.Const{name: :zero}},
             arg: %Term.App{fun: %Term.Const{name: :vec_nil}, arg: %Term.BVar{index: 3}}
           } = vec_nil_shape.case_result

    assert [%Term.App{}] = vec_cons_shape.index_patterns

    assert [
             _,
             %Term.App{
               fun: %Term.App{
                 fun: %Term.App{
                   fun: %Term.App{fun: %Term.Const{name: :vec_cons}, arg: %Term.BVar{index: 8}},
                   arg: %Term.BVar{index: 3}
                 },
                 arg: %Term.BVar{index: 2}
               },
               arg: %Term.BVar{index: 1}
             }
           ] = vec_cons_shape.motive_arguments

    assert %Term.App{fun: %Term.App{fun: %Term.BVar{index: 7}}, arg: %Term.App{}} =
             vec_cons_shape.case_result

    assert %{
             binder_type: %Term.Forall{
               body: %Term.Forall{body: %Term.Forall{body: %Term.Forall{body: case_result}}}
             }
           } = vec_cons_shape

    assert case_result == vec_cons_shape.case_result

    assert matcher_shape.recursor_arguments == [
             Term.bvar(5),
             Term.bvar(4),
             Term.bvar(1),
             Term.bvar(0),
             Term.bvar(3),
             Term.bvar(2)
           ]

    assert {fun, args} = TermApplication.collect(matcher_shape.body)
    assert fun == Term.const(:vec_ind, [1])
    assert args == matcher_shape.recursor_arguments

    assert MatcherType.from_descriptor(matcher_descriptor) ==
             {:error, {:unsupported_indexed_matcher_type, :Vec}}

    assert MatcherType.value_from_descriptor(matcher_descriptor) ==
             {:error, {:unsupported_indexed_matcher_value, :Vec}}
  end

  test "experimental indexed matcher emission returns planned terms without enabling checked declarations" do
    descriptor = vec_matcher_descriptor!()
    shape = vec_matcher_shape!()

    assert {:ok, type} = MatcherType.indexed_from_descriptor(descriptor)

    assert collect_foralls(type) ==
             {[:a, :motive, :n, :xs, :on_vec_nil, :on_vec_cons], shape.result}

    assert {:ok, value} = MatcherType.indexed_value_from_descriptor(descriptor)
    assert {[:a, :motive, :n, :xs, :on_vec_nil, :on_vec_cons], body} = collect_lams(value)
    assert {fun, args} = TermApplication.collect(body)
    assert fun == Term.const(:vec_ind, [1])
    assert args == shape.recursor_arguments

    {:ok, env} = Prelude.env()
    {:ok, nat_info} = Info.fetch(env, :nat_add)
    {:ok, nat_descriptor} = MatcherDescriptor.from_env(env, nat_info.schema, nat_info.matcher)

    assert MatcherType.indexed_from_descriptor(nat_descriptor) ==
             {:error, {:not_indexed_matcher_type, :nat}}

    assert MatcherType.indexed_value_from_descriptor(nat_descriptor) ==
             {:error, {:not_indexed_matcher_value, :nat}}
  end

  test "experimental indexed matcher type is well-formed but value is not admitted yet" do
    {:ok, env} = Prelude.env()
    descriptor = vec_matcher_descriptor!()
    assert {:ok, type} = MatcherType.indexed_from_descriptor(descriptor)
    assert {:ok, value} = MatcherType.indexed_value_from_descriptor(descriptor)

    assert {:ok, %Term.Sort{}} = Kernel.infer(env, type)
    assert {:error, _reason} = Kernel.check(env, value, type)
  end

  test "matcher type shape validation rejects corrupted indexed plans" do
    shape = vec_matcher_shape!()
    [nil_alt, cons_alt] = shape.alternatives

    assert MatcherType.validate_shape(shape) == :ok
    assert shape.recursor_descriptor.recursor.name == :vec_ind
    assert shape.recursor_descriptor.recursor.num_params == 1
    assert shape.recursor_descriptor.recursor.num_indices == 1
    assert shape.recursor_descriptor.recursor.num_motives == 1
    assert shape.recursor_descriptor.recursor.num_minors == 2

    assert MatcherType.validate_shape(%{shape | motive_arguments: []}) ==
             {:error, {:motive_argument_count_mismatch, :Vec}}

    assert MatcherType.validate_shape(%{shape | index_patterns: %{}}) ==
             {:error, {:missing_index_patterns, :vec_nil}}

    assert MatcherType.validate_shape(%{shape | recursor_arguments: []}) ==
             {:error, {:recursor_argument_count_mismatch, :vec_ind, 6, 0}}

    broken_case = %{cons_alt | case_result: nil}

    assert MatcherType.validate_shape(%{shape | alternatives: [nil_alt, broken_case]}) ==
             {:error, {:missing_case_result, :vec_cons}}

    assert MatcherType.validate_shape(%{shape | alternatives: [nil_alt]}) ==
             {:error, {:alternative_binder_count_mismatch, :Vec}}

    assert MatcherType.validate_shape(%{shape | indices: []}) ==
             {:error, {:recursor_index_count_mismatch, :vec_ind, 1, 0}}
  end

  test "matcher descriptor validation rejects corrupted shapes" do
    info = MatcherInfo.new(:match_nat, 0, 1, [%Alternative{constructor: :zero, num_fields: 0}])

    base = %MatcherDescriptor{
      family: :nat,
      parameters: [],
      discriminants: info.discriminants,
      alternatives: [
        %MatcherDescriptor.Alternative{
          name: :zero,
          pattern: [:zero],
          fields: [],
          result: Term.bvar(1)
        }
      ],
      result: Term.bvar(0),
      recursor: :nat_rec
    }

    duplicate = %{base | alternatives: base.alternatives ++ base.alternatives}
    wrong_discriminants = %{base | discriminants: []}
    wrong_alternatives = %{base | alternatives: []}
    unsupported_recursor = %{base | recursor: :vec_rec}

    assert MatcherDescriptor.validate(duplicate, %{info | alternatives: duplicate.alternatives}) ==
             {:error, :duplicate_alternative}

    assert MatcherDescriptor.validate(wrong_discriminants, info) ==
             {:error, {:discriminant_count_mismatch, 1}}

    assert MatcherDescriptor.validate(wrong_alternatives, info) ==
             {:error, {:alternative_count_mismatch, 1}}

    assert MatcherDescriptor.validate(unsupported_recursor, info) ==
             {:error, {:unsupported_recursor, :vec_rec}}
  end

  test "matcher descriptors drive real matcher types and bodies" do
    {:ok, env} = Prelude.env()

    for definition <- [:bool_not, :bool_and, :nat_add, :list_append] do
      {:ok, info} = Info.fetch(env, definition)
      {:ok, descriptor} = MatcherDescriptor.from_env(env, info.schema, info.matcher)
      {:ok, matcher} = Theoria.Env.fetch_matcher(env, info.matcher.name)

      assert descriptor.family == info.schema.family
      assert length(descriptor.alternatives) == length(info.matcher.alternatives)
      assert {:ok, type} = MatcherType.from_descriptor(descriptor)
      assert {:ok, value} = MatcherType.value_from_descriptor(descriptor)
      assert type == matcher.type
      assert value == matcher.value
    end
  end

  test "matcher descriptors normalize fields across construction paths" do
    {:ok, env} = Prelude.env()

    for definition <- [:nat_add, :list_append] do
      {:ok, info} = Info.fetch(env, definition)
      assert {:ok, fallback} = MatcherDescriptor.from_schema(info.schema, info.matcher)
      assert {:ok, recursor} = RecursorDescriptor.from_schema(env, info.schema)
      assert {:ok, derived} = MatcherDescriptor.from_recursor(info.schema, info.matcher, recursor)
      assert {:ok, env_derived} = MatcherDescriptor.from_env(env, info.schema, info.matcher)

      for descriptor <- [fallback, derived, env_derived],
          alternative <- descriptor.alternatives do
        assert Enum.all?(alternative.fields, &match?(%MatcherDescriptor.Field{}, &1))
      end
    end
  end

  test "environment matcher descriptors reuse checked recursor rule fields" do
    {:ok, env} = Prelude.env()
    {:ok, nat_info} = Info.fetch(env, :nat_add)
    {:ok, list_info} = Info.fetch(env, :list_append)

    assert {:ok, nat_descriptor} =
             MatcherDescriptor.from_env(env, nat_info.schema, nat_info.matcher)

    assert [%{name: :zero, fields: []}, succ_alt] = nat_descriptor.alternatives
    assert Enum.map(succ_alt.fields, & &1.name) == [:field0]
    assert Enum.map(succ_alt.recursive_fields, & &1.name) == [:field0]

    assert {:ok, list_descriptor} =
             MatcherDescriptor.from_env(env, list_info.schema, list_info.matcher)

    assert [%{name: :list_nil, fields: []}, cons_alt] = list_descriptor.alternatives
    assert Enum.map(cons_alt.fields, & &1.name) == [:field0, :field1]
    assert Enum.map(cons_alt.recursive_fields, & &1.name) == [:field1]
  end

  test "matcher type shapes plan simple matcher telescopes" do
    {:ok, env} = Prelude.env()

    cases = [
      bool_not: {[:b], [:on_true, :on_false]},
      bool_and: {[:a, :b], [:on_true_true, :on_true_false, :on_false_true, :on_false_false]},
      nat_add: {[:n], [:on_zero, :on_succ]},
      list_append: {[:xs], [:on_nil, :on_cons]}
    ]

    for {definition, {discriminants, alternatives}} <- cases do
      {:ok, info} = Info.fetch(env, definition)
      {:ok, descriptor} = MatcherDescriptor.from_env(env, info.schema, info.matcher)
      assert {:ok, shape} = MatcherType.shape_from_descriptor(descriptor)
      assert shape.motive_name == :motive
      assert Enum.map(shape.discriminant_binders, &elem(&1, 0)) == discriminants
      assert Enum.map(shape.alternative_binders, &elem(&1, 0)) == alternatives
      assert Enum.map(shape.alternatives, & &1.binder_name) == alternatives

      assert Enum.map(shape.alternatives, & &1.binder_type) ==
               Enum.map(shape.alternative_binders, &elem(&1, 1))
    end

    {:ok, nat_info} = Info.fetch(env, :nat_add)
    {:ok, nat_descriptor} = MatcherDescriptor.from_env(env, nat_info.schema, nat_info.matcher)
    {:ok, nat_shape} = MatcherType.shape_from_descriptor(nat_descriptor)

    assert [_, %{binder_type: %Term.Forall{domain: %Term.Const{name: :Nat}}}] =
             nat_shape.alternatives

    assert nat_shape.recursor_arguments == [
             Term.bvar(3),
             Term.bvar(1),
             Term.bvar(0),
             Term.bvar(2)
           ]

    {:ok, list_info} = Info.fetch(env, :list_append)
    {:ok, list_descriptor} = MatcherDescriptor.from_env(env, list_info.schema, list_info.matcher)
    {:ok, list_shape} = MatcherType.shape_from_descriptor(list_descriptor)

    assert [_, %{binder_type: %Term.Forall{body: %Term.Forall{body: %Term.Forall{}}}}] =
             list_shape.alternatives

    assert list_shape.recursor_arguments == [
             Term.bvar(4),
             Term.bvar(3),
             Term.bvar(1),
             Term.bvar(0),
             Term.bvar(2)
           ]
  end

  test "matcher type builds real Bool, Nat, and List matcher shapes" do
    {:ok, env} = Prelude.env()
    {:ok, bool_info} = Info.fetch(env, :bool_not)
    {:ok, binary_bool_info} = Info.fetch(env, :bool_and)
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

    assert [_true_alt, _false_alt] =
             MatcherType.alternatives(bool_info.schema, bool_info.matcher)

    assert {:ok, binary_bool_type} =
             MatcherType.build(binary_bool_info.schema, binary_bool_info.matcher)

    assert %Term.Forall{
             name: :motive,
             body: %Term.Forall{
               name: :a,
               body: %Term.Forall{name: :b, body: %Term.Forall{name: :on_true_true}}
             }
           } = binary_bool_type

    assert [
             %MatcherType.Alternative{constructor: :true_true, fields: []},
             %MatcherType.Alternative{constructor: :true_false, fields: []},
             %MatcherType.Alternative{constructor: :false_true, fields: []},
             %MatcherType.Alternative{constructor: :false_false, fields: []}
           ] = MatcherType.alternatives(binary_bool_info.schema, binary_bool_info.matcher)

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
               fields: [%MatcherDescriptor.Field{name: :pred, type: %Term.Const{name: :Nat}}]
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
               fields: [
                 %MatcherDescriptor.Field{name: :head},
                 %MatcherDescriptor.Field{name: :tail}
               ]
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
    assert {:ok, unfold_theorem} = Eqns.realize(env, :"nat_add.eq_def")
    assert unfold_theorem.name == :"nat_add.eq_def"
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
          bool_and: :"bool_and.match_1",
          bool_or: :"bool_or.match_1",
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

  defp vec_matcher_descriptor! do
    {:ok, env} = Prelude.env()

    vec_schema =
      Schema.new(:Vec, [],
        recursive_argument: 1,
        parameter_binders: [a: Term.sort(1)],
        argument_binders: [n: Term.const(:Nat), xs: Term.const(:Vec)]
      )

    matcher =
      MatcherInfo.new(:vec_match, 1, 1, [
        %Alternative{constructor: :vec_nil, num_fields: 0},
        %Alternative{constructor: :vec_cons, num_fields: 3}
      ])

    {:ok, descriptor} = MatcherDescriptor.from_env(env, vec_schema, matcher)
    descriptor
  end

  defp vec_matcher_shape! do
    {:ok, shape} = MatcherType.shape_from_descriptor(vec_matcher_descriptor!())
    shape
  end

  defp corrupt_matcher(env, name, fun) do
    {:ok, constant} = Theoria.Env.fetch(env, name)
    constant = %{constant | metadata: fun.(constant.metadata)}
    %{env | constants: Map.put(env.constants, name, constant)}
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

  defp collect_foralls(%Term.Forall{name: name, body: body}) do
    {names, body} = collect_foralls(body)
    {[name | names], body}
  end

  defp collect_foralls(body), do: {[], body}
end
