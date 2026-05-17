defmodule Theoria.EquationTest do
  use ExUnit.Case, async: true

  alias Theoria.Equation
  alias Theoria.Equation.{Clause, Pattern}
  alias Theoria.Term

  test "builds Bool recursor applications" do
    term = Equation.bool(Term.const(:Bool), Term.const(false), Term.const(true), Term.const(true))

    assert {%Term.Const{name: :bool_rec}, args} = Term.Application.collect(term)
    assert args == [Term.const(:Bool), Term.const(false), Term.const(true), Term.const(true)]
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
