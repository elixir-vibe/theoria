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

  test "reports missing Bool constructor clauses" do
    assert {:error, {:missing_clause, missing}} =
             Equation.compile_bool(Term.const(:Bool), [], Term.const(true))

    assert missing in [true, false]
  end

  test "builds Nat recursor applications" do
    succ_case = Term.lam(:n, Term.const(:Nat), Term.bvar(0))
    term = Equation.nat(Term.const(:Nat), Term.const(:zero), succ_case, Term.const(:zero))

    assert {%Term.Const{name: :nat_rec}, args} = Term.Application.collect(term)
    assert args == [Term.const(:Nat), Term.const(:zero), succ_case, Term.const(:zero)]
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
end
