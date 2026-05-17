defmodule Theoria.NormalizeTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Theoria.Env
  alias Theoria.Kernel
  alias Theoria.Normalize

  import Theoria.Term

  describe "normalization" do
    test "unfolds checked definitions" do
      type0 = sort(0)
      identity_type = forall(:a, type0, arrow(bvar(0), bvar(0)))
      identity_proof = lam(:a, type0, lam(:x, bvar(0), bvar(0)))
      {:ok, env} = Kernel.add_definition(Env.new(), :id, identity_type, identity_proof)

      term = const(:id) |> app(type0) |> app(type0)

      assert {:ok, normalized} = Normalize.normalize(env, term)
      assert normalized == type0
    end

    test "does not unfold opaque constants" do
      type0 = sort(0)
      {:ok, env} = Kernel.add_constant(Env.new(), :Nat, type0)

      assert {:ok, normalized} = Normalize.normalize(env, const(:Nat))
      assert normalized == const(:Nat)
    end
  end

  property "normalization is idempotent for generated core terms" do
    check all(term <- term_generator()) do
      env = Env.new()
      assert {:ok, once} = Normalize.normalize(env, term)
      assert {:ok, twice} = Normalize.normalize(env, once)
      assert once == twice
    end
  end

  property "shifting by zero is identity for generated core terms" do
    check all(term <- term_generator()) do
      assert shift(term, 0) == term
    end
  end

  defp term_generator do
    leaf =
      one_of([
        constant(sort(0)),
        constant(sort(1)),
        map(integer(0..2), &bvar/1),
        map(member_of([:Nat, :zero, :id]), &const/1)
      ])

    tree(leaf, fn child ->
      one_of([
        map({child, child}, fn {fun, arg} -> app(fun, arg) end),
        map({member_of([:x, :y]), child, child}, fn {name, domain, body} ->
          lam(name, domain, body)
        end),
        map({member_of([:x, :y]), child, child}, fn {name, domain, body} ->
          forall(name, domain, body)
        end),
        map({child, child, child}, fn {type, left, right} -> eq(type, left, right) end),
        map(child, &refl/1),
        map({child, child, child, child}, fn {type, motive, base, proof} ->
          eq_rec(type, motive, base, proof)
        end)
      ])
    end)
  end
end
