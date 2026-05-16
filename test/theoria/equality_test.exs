defmodule Theoria.EqualityTest do
  use ExUnit.Case, async: true

  alias Theoria.Env
  alias Theoria.Kernel
  alias Theoria.Normalize

  import Theoria.Term

  describe "propositional equality" do
    test "infers equality as a proposition-like sort" do
      type0 = sort(0)
      context = Theoria.Context.new() |> Theoria.Context.push(:x, type0)

      assert {:ok, inferred} = Kernel.infer(Env.new(), context, eq(type0, bvar(0), bvar(0)))
      assert inferred == sort(0)
    end

    test "rejects equality whose declared type is not a type" do
      {:ok, env} = Kernel.add_constant(Env.new(), :Nat, sort(0))
      {:ok, env} = Kernel.add_constant(env, :zero, const(:Nat))

      assert {:error, error} = Kernel.infer(env, eq(const(:zero), const(:zero), const(:zero)))
      assert error.reason == :expected_sort
    end

    test "infers reflexivity proof" do
      type0 = sort(0)
      context = Theoria.Context.new() |> Theoria.Context.push(:x, type0)

      assert {:ok, inferred} = Kernel.infer(Env.new(), context, refl(bvar(0)))
      assert Normalize.defeq?(Env.new(), inferred, eq(type0, bvar(0), bvar(0)))
    end

    test "checks forall A, forall x : A, x = x" do
      type0 = sort(0)

      theorem_type =
        forall(:a, type0, forall(:x, bvar(0), eq(bvar(1), bvar(0), bvar(0))))

      proof =
        lam(:a, type0, lam(:x, bvar(0), refl(bvar(0))))

      assert :ok = Kernel.check(Env.new(), proof, theorem_type)
    end
  end
end
