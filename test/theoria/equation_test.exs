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
    succ_case = Term.lam(:n, Term.const(:Nat), Term.bvar(0))
    term = Equation.nat(Term.const(:Nat), Term.const(:zero), succ_case, Term.const(:zero))

    assert {%Term.Const{name: :nat_rec}, args} = Term.Application.collect(term)
    assert args == [Term.const(:Nat), Term.const(:zero), succ_case, Term.const(:zero)]
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
             Term.app(Term.const(:List), Term.const(:Nat)),
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
    succ_case = Term.lam(:n, Term.const(:Nat), Term.bvar(0))

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
    assert args == [Term.const(:Nat), Term.const(:zero), succ_case, Term.const(:zero)]
  end

  test "materializes Nat succ branches from non-lambda bodies" do
    assert {:ok, term} =
             Equation.compile_nat(
               Term.const(:Nat),
               [
                 Clause.new([Pattern.constructor(:zero)], Term.const(:zero)),
                 Clause.new([Pattern.constructor(:succ, [Pattern.var(:n)])], Term.bvar(0))
               ],
               Term.const(:zero)
             )

    assert {%Term.Const{name: :nat_rec}, [_motive, _zero, succ_case, _major]} =
             Term.Application.collect(term)

    ih = Term.bvar(0)
    assert %Term.Lam{name: :pred, body: %Term.Lam{name: :ih, body: ^ih}} = succ_case
  end

  test "builds List recursor applications" do
    list = Term.app(Term.const(:List), Term.const(:Nat))
    cons_case = Term.lam(:x, Term.const(:Nat), Term.bvar(0))

    term =
      Equation.list(Term.const(:Nat), list, Term.const(:list_nil), cons_case, Term.const(:xs))

    assert {%Term.Const{name: :list_rec}, args} = Term.Application.collect(term)
    assert args == [Term.const(:Nat), list, Term.const(:list_nil), cons_case, Term.const(:xs)]
  end

  test "compiles List constructor clauses" do
    list = Term.app(Term.const(:List), Term.const(:Nat))
    cons_case = Term.lam(:x, Term.const(:Nat), Term.bvar(0))

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
    assert args == [Term.const(:Nat), list, Term.const(:list_nil), cons_case, Term.const(:xs)]
  end

  test "materializes List cons branches from non-lambda bodies" do
    list = Term.app(Term.const(:List), Term.const(:Nat))

    assert {:ok, term} =
             Equation.compile_list(
               Term.const(:Nat),
               list,
               [
                 Clause.new([Pattern.constructor(:list_nil)], Term.const(:list_nil)),
                 Clause.new(
                   [Pattern.constructor(:list_cons, [Pattern.var(:x), Pattern.var(:xs)])],
                   Term.bvar(0)
                 )
               ],
               Term.const(:xs)
             )

    assert {%Term.Const{name: :list_rec}, [_element_type, _motive, _nil, cons_case, _major]} =
             Term.Application.collect(term)

    ih = Term.bvar(0)

    assert %Term.Lam{
             name: :head,
             body: %Term.Lam{name: :tail, body: %Term.Lam{name: :ih, body: ^ih}}
           } =
             cons_case
  end
end
