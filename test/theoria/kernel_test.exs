defmodule Theoria.KernelTest do
  use ExUnit.Case, async: true

  alias Theoria.Context
  alias Theoria.Env
  alias Theoria.Kernel
  alias Theoria.Normalize
  alias Theoria.Term

  import Theoria.Term

  describe "dependent functions" do
    test "checks the identity proof" do
      type0 = sort(0)

      identity_type =
        forall(:a, type0, forall(:x, bvar(0), bvar(1)))

      identity_proof =
        lam(:a, type0, lam(:x, bvar(0), bvar(0)))

      assert :ok = Kernel.check(Env.new(), identity_proof, identity_type)
    end

    test "rejects a proof with the wrong returned variable" do
      type0 = sort(0)

      const_type =
        forall(:a, type0, forall(:b, type0, forall(:x, bvar(1), forall(:y, bvar(1), bvar(3)))))

      bad_proof =
        lam(:a, type0, lam(:b, type0, lam(:x, bvar(1), lam(:y, bvar(1), bvar(0)))))

      assert {:error, error} = Kernel.check(Env.new(), bad_proof, const_type)
      assert error.reason == :type_mismatch
    end
  end

  describe "application" do
    test "infers beta-reduced result types" do
      type0 = sort(0)

      identity =
        lam(:a, type0, lam(:x, bvar(0), bvar(0)))

      context =
        Context.new()
        |> Context.push(:nat, type0)
        |> Context.push(:zero, bvar(0))

      term =
        identity
        |> app(bvar(1))
        |> app(bvar(0))

      assert {:ok, inferred} = Kernel.infer(Env.new(), context, term)
      assert Normalize.defeq?(Env.new(), inferred, bvar(1))
    end
  end

  describe "environment" do
    test "admits checked definitions" do
      type0 = sort(0)
      identity_type = forall(:a, type0, arrow(bvar(0), bvar(0)))
      identity_proof = lam(:a, type0, lam(:x, bvar(0), bvar(0)))

      assert {:ok, env} = Kernel.add_definition(Env.new(), :id, identity_type, identity_proof)
      assert {:ok, type} = Kernel.infer(env, Term.const(:id))
      assert Normalize.defeq?(env, type, identity_type)
    end

    test "rejects unchecked definitions" do
      assert {:error, error} = Kernel.add_definition(Env.new(), :bad, sort(0), sort(0))
      assert error.reason == :type_mismatch
    end
  end
end
