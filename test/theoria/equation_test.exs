defmodule Theoria.EquationTest do
  use ExUnit.Case, async: true

  alias Theoria.Equation
  alias Theoria.Equation.{Branch, Clause, Context, Lemma, Pattern}
  alias Theoria.Term

  test "equation lemma metadata becomes defeq checks" do
    lemma = Lemma.new(:equation_zero, zero(), zero())
    check = Lemma.defeq_check(lemma, :nat)

    assert check.name == "equation_zero"
    assert check.category == :nat
    assert check.left == zero()
    assert check.right == zero()
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
  end

  test "builds Bool recursor applications" do
    term = Equation.bool(Term.const(:Bool), Term.const(false), Term.const(true), Term.const(true))

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
    term = Equation.nat(nat(), zero(), succ_case, zero())

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
      Equation.list(nat(), list, Term.const(:list_nil), cons_case, Term.const(:xs))

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
