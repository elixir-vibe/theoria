defmodule Theoria.Library.Bool.DependentInductionTest do
  use ExUnit.Case, async: true

  alias Theoria.Kernel
  alias Theoria.Library.Bool
  alias Theoria.Normalize

  import Theoria.Term

  test "bool_ind type checks" do
    {:ok, env} = Bool.env()

    assert {:ok, _type} = Kernel.infer(env, const(:bool_ind, [1]))
  end

  test "bool_ind reduces true" do
    {:ok, env} = Bool.env()

    term =
      const(:bool_ind, [1])
      |> app(constant_bool_motive())
      |> app(const(true))
      |> app(const(false))
      |> app(const(true))

    assert Normalize.defeq?(env, term, const(true))
  end

  test "bool_ind reduces false" do
    {:ok, env} = Bool.env()

    term =
      const(:bool_ind, [1])
      |> app(constant_bool_motive())
      |> app(const(true))
      |> app(const(false))
      |> app(const(false))

    assert Normalize.defeq?(env, term, const(false))
  end

  test "bool_ind checks a dependent equality motive" do
    {:ok, env} = Bool.env()

    proof =
      const(:bool_ind, [0])
      |> app(reflexive_motive())
      |> app(refl(const(true)))
      |> app(refl(const(false)))

    expected = forall(:b, const(:Bool), eq(const(:Bool), bvar(0), bvar(0)))

    assert :ok = Kernel.check(env, proof, expected)
  end

  defp constant_bool_motive do
    lam(:_b, const(:Bool), const(:Bool))
  end

  defp reflexive_motive do
    lam(:b, const(:Bool), eq(const(:Bool), bvar(0), bvar(0)))
  end
end
