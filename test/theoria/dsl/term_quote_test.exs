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
    assert term(do: var(x)) == var(:x)
    assert term(do: prop()) == prop()
    assert term(do: bool_true()) == const(true)
    assert term(do: bool_false()) == const(false)
    assert term(do: true_prop()) == const(:True)
    assert term(do: false_prop()) == const(:False)
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
