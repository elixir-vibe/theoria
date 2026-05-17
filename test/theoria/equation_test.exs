defmodule Theoria.EquationTest do
  use ExUnit.Case, async: true

  alias Theoria.Equation
  alias Theoria.Term

  test "builds Bool recursor applications" do
    term = Equation.bool(Term.const(:Bool), Term.const(false), Term.const(true), Term.const(true))

    assert {%Term.Const{name: :bool_rec}, args} = Term.Application.collect(term)
    assert args == [Term.const(:Bool), Term.const(false), Term.const(true), Term.const(true)]
  end

  test "builds Nat recursor applications" do
    succ_case = Term.lam(:n, Term.const(:Nat), Term.bvar(0))
    term = Equation.nat(Term.const(:Nat), Term.const(:zero), succ_case, Term.const(:zero))

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
end
