defmodule Theoria.DSL.TermQuoteTest do
  use ExUnit.Case, async: true

  alias Theoria.Env
  alias Theoria.Kernel
  alias Theoria.Syntax, as: S

  import Theoria.DSL

  test "turns bare variables into Theoria variables" do
    assert term(do: x) == S.var(:x)
  end

  test "turns calls into constant applications" do
    assert term(do: and_intro(q, p, and_right(p, q, h), and_left(p, q, h))) ==
             call(
               const(:and_intro),
               var(:q),
               var(:p),
               call(const(:and_right), var(:p), var(:q), var(:h)),
               call(const(:and_left), var(:p), var(:q), var(:h))
             )
  end

  test "supports explicit const, var, eq, refl, prop, type, and arrow forms" do
    assert term(do: eq(type(0), x, x)) == eq(type(0), var(:x), var(:x))
    assert term(do: refl(x)) == refl(var(:x))
    assert term(do: const(:True)) == const(:True)
    assert term(do: const(:List, [1])) == const(:List, [1])
    assert term(do: var(x)) == var(:x)
    assert term(do: prop()) == prop()
    assert term(do: bool()) == const(:Bool)
    assert term(do: nat()) == const(:Nat)
    assert term(do: bool_true()) == const(true)
    assert term(do: bool_false()) == const(false)
    assert term(do: true_prop()) == const(:True)
    assert term(do: false_prop()) == const(:False)
    assert term(do: zero) == const(:zero)
    assert term(do: succ) == const(:succ)
    assert term(do: list(a)) == call(const(:List, [1]), var(:a))
    assert term(do: list(a, 2)) == call(const(:List, [2]), var(:a))
    assert term(do: list_nil) == const(:list_nil, [1])
    assert term(do: list_cons) == const(:list_cons, [1])

    assert term(do: bool_rec(bool(), bool_true(), bool_false(), bool_true())) ==
             call(const(:bool_rec, [1]), [const(:Bool), const(true), const(false), const(true)])

    assert term(do: nat_rec(nat(), zero, succ, zero)) ==
             call(const(:nat_rec, [1]), [const(:Nat), const(:zero), const(:succ), const(:zero)])

    assert term(do: nat_ind(f, z, s, n)) ==
             call(const(:nat_ind, [1]), [var(:f), var(:z), var(:s), var(:n)])

    assert term(do: list_rec(nat(), nat(), zero, succ, list_nil(nat()))) ==
             call(const(:list_rec, [1, 1]), [
               const(:Nat),
               const(:Nat),
               const(:zero),
               const(:succ),
               call(const(:list_nil, [1]), const(:Nat))
             ])

    assert term(do: arrow(p, q)) == arrow(var(:p), var(:q))
    assert term(do: app(f, x)) == app(var(:f), var(:x))
    assert term(do: conj(p, q)) == call(const(:and), var(:p), var(:q))
    assert term(do: neg(p)) == call(const(:not), var(:p))
  end

  test "supports binder forms" do
    assert term(
             do:
               forall :p, prop() do
                 arrow(p, p)
               end
           ) == S.forall(:p, S.sort(0), S.arrow(S.var(:p), S.var(:p)))

    assert term(
             do:
               lam p, prop() do
                 p
               end
           ) == S.lam(:p, S.sort(0), S.var(:p))

    assert term(
             do:
               let :x, prop(), true_prop() do
                 x
               end
           ) == S.let(:x, S.sort(0), S.const(:True), S.var(:x))
  end

  test "quoted term can be elaborated and checked" do
    type =
      forall :p, prop() do
        forall :hp, var(:p) do
          var(:p)
        end
      end

    proof =
      lam :p, prop() do
        lam :hp, var(:p) do
          term(do: hp)
        end
      end

    assert :ok = Kernel.check(Env.new(), elab!(proof), elab!(type))
  end
end
