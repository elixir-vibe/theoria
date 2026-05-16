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

  test "supports explicit const, var, eq, refl, prop, and type forms" do
    assert term(do: eq(type(0), x, x)) == eq(type(0), var(:x), var(:x))
    assert term(do: refl(x)) == refl(var(:x))
    assert term(do: const(:True)) == const(:True)
    assert term(do: var(x)) == var(:x)
    assert term(do: prop()) == prop()
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
