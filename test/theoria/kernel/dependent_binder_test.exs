defmodule Theoria.Kernel.DependentBinderTest do
  use ExUnit.Case, async: true

  alias Theoria.Env
  alias Theoria.Kernel

  import Theoria.DSL

  test "checks K combinator under nested dependent binders" do
    type =
      forall :p, prop() do
        forall :q, prop() do
          forall :hp, var(:p) do
            forall :_hq, var(:q) do
              var(:p)
            end
          end
        end
      end

    proof =
      lam :p, prop() do
        lam :q, prop() do
          lam :hp, var(:p) do
            lam :_hq, var(:q) do
              var(:hp)
            end
          end
        end
      end

    assert :ok = Kernel.check(Env.new(), elab!(proof), elab!(type))
  end
end
