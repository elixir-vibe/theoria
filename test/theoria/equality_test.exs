defmodule Theoria.EqualityTest do
  use ExUnit.Case, async: true

  alias Theoria.Env
  alias Theoria.Kernel
  alias Theoria.Library.Nat
  alias Theoria.Normalize
  alias Theoria.Prelude

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

    test "equality recursor infers transported motive" do
      {:ok, env} = Nat.env()

      context =
        Theoria.Context.new()
        |> Theoria.Context.push(:m, const(:Nat))
        |> Theoria.Context.push(:p, eq(const(:Nat), const(:zero), bvar(0)))

      motive = lam(:x, const(:Nat), eq(const(:Nat), const(:zero), bvar(0)))
      term = eq_rec(const(:Nat), motive, refl(const(:zero)), bvar(0))

      assert {:ok, inferred} = Kernel.infer(env, context, term)
      assert Normalize.defeq?(env, inferred, eq(const(:Nat), const(:zero), bvar(1)))
    end

    test "equality recursor reduces on reflexivity" do
      {:ok, env} = Nat.env()

      term =
        eq_rec(
          const(:Nat),
          lam(:n, const(:Nat), const(:Nat)),
          const(:zero),
          refl(const(:zero))
        )

      assert Kernel.check(env, term, const(:Nat)) == :ok
      assert Normalize.normalize(env, term) == {:ok, const(:zero)}
    end

    test "equality recursor rejects a base case outside the motive" do
      {:ok, env} = Nat.env()

      term =
        eq_rec(
          const(:Nat),
          lam(:n, const(:Nat), eq(const(:Nat), bvar(0), bvar(0))),
          const(:zero),
          refl(const(:zero))
        )

      assert {:error, error} = Kernel.infer(env, term)
      assert error.reason == :type_mismatch
    end

    test "equality recursor rejects non-equality proofs" do
      {:ok, env} = Nat.env()

      term = eq_rec(const(:Nat), lam(:n, const(:Nat), const(:Nat)), const(:zero), const(:zero))

      assert {:error, error} = Kernel.infer(env, term)
      assert error.reason == :expected_equality
    end

    test "equality recursor rejects equality over a different type" do
      {:ok, env} = Prelude.env()

      term =
        eq_rec(
          const(:Bool),
          lam(:b, const(:Bool), const(:Bool)),
          const(true),
          refl(const(:zero))
        )

      assert {:error, error} = Kernel.infer(env, term)
      assert error.reason == :equality_type_mismatch
    end

    test "equality recursor rejects motives whose left side is not a sort" do
      {:ok, env} = Nat.env()

      term =
        eq_rec(const(:Nat), lam(:n, const(:Nat), const(:zero)), const(:zero), refl(const(:zero)))

      assert {:error, error} = Kernel.infer(env, term)
      assert error.reason == :expected_sort
    end

    test "equality recursor stays stuck when proof is not reflexivity" do
      term = eq_rec(const(:Nat), lam(:n, const(:Nat), const(:Nat)), const(:zero), const(:h))

      assert Normalize.normalize(Env.new(), term) == {:ok, term}
    end
  end
end
