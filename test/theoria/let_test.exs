defmodule Theoria.LetTest do
  use ExUnit.Case, async: true

  alias Theoria.Elaborator
  alias Theoria.Env
  alias Theoria.Kernel
  alias Theoria.Library.Logic
  alias Theoria.Normalize
  alias Theoria.Syntax, as: S
  alias Theoria.Term, as: T

  import Theoria.DSL
  import Theoria.Term, except: [app: 2, arrow: 2, const: 1, eq: 3, lam: 3, refl: 1]

  test "elaborates let-bound variables" do
    syntax = S.let(:x, S.sort(0), S.const(:True), S.var(:x))

    assert Elaborator.elaborate(syntax) ==
             {:ok, let(:x, sort(0), T.const(:True), bvar(0))}
  end

  test "infers dependent let body type" do
    {:ok, env} = Logic.env()
    term = let(:x, T.const(:True), T.const(:true_intro), bvar(0))

    assert Kernel.infer(env, term) == {:ok, T.const(:True)}
  end

  test "normalization zeta-reduces lets" do
    {:ok, env} = Logic.env()
    term = let(:x, T.const(:True), T.const(:true_intro), bvar(0))

    assert Normalize.normalize(env, term) == {:ok, T.const(:true_intro)}
  end

  test "let substitution avoids capture" do
    body = T.lam(:y, sort(0), bvar(1))
    term = let(:x, sort(0), bvar(0), body)

    assert Normalize.normalize(Env.new(), term) == {:ok, T.lam(:y, sort(0), bvar(1))}
  end

  test "quoted let proof checks" do
    {:ok, env} = Logic.env()

    type =
      term do
        forall :p, prop() do
          arrow(p, p)
        end
      end

    proof =
      term do
        lam :p, prop() do
          lam :hp, p do
            let :x, p, hp do
              x
            end
          end
        end
      end

    assert :ok = Kernel.check(env, elab!(proof), elab!(type))
  end
end
