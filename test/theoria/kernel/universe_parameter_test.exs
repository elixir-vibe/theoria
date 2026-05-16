defmodule Theoria.Kernel.UniverseParameterTest do
  use ExUnit.Case, async: true

  alias Theoria.Env
  alias Theoria.Env.Constant
  alias Theoria.Error
  alias Theoria.Kernel
  alias Theoria.Level
  alias Theoria.Normalize
  alias Theoria.Term

  import Theoria.Term

  test "infers universe-polymorphic constant instances" do
    {:ok, env} = Kernel.add_constant(Env.new(), :Box, sort(Level.param(:u)), [:u])

    assert Kernel.infer(env, const(:Box, [0])) == {:ok, sort(0)}
    assert Kernel.infer(env, const(:Box, [2])) == {:ok, sort(2)}
  end

  test "rejects constants with wrong universe argument counts" do
    {:ok, env} = Kernel.add_constant(Env.new(), :Box, sort(Level.param(:u)), [:u])

    assert {:error, %Error{reason: :universe_arity_mismatch}} = Kernel.infer(env, const(:Box))

    assert {:error, %Error{reason: :universe_arity_mismatch}} =
             Kernel.infer(env, const(:Box, [0, 1]))
  end

  test "rejects undeclared universe parameters in declarations" do
    assert {:error, %Error{reason: :unknown_universe_parameter}} =
             Kernel.add_constant(Env.new(), :Box, sort(Level.param(:u)))
  end

  test "rejects duplicate universe parameters in declarations" do
    assert {:error, %Error{reason: :duplicate_universe_parameter}} =
             Kernel.add_constant(Env.new(), :Box, sort(Level.param(:u)), [:u, :u])
  end

  test "environment validation preserves universe parameters" do
    {:ok, env} = Kernel.add_constant(Env.new(), :Box, sort(Level.param(:u)), [:u])

    assert {:ok, checked_env} = Kernel.validate_env(env)
    assert {:ok, %Constant{universe_params: [:u]}} = Env.fetch(checked_env, :Box)
  end

  test "level substitution walks terms and constant universe arguments" do
    term = forall(:x, sort(Level.param(:u)), const(:Box, [Level.succ(Level.param(:u))]))

    assert Term.subst_levels(term, %{u: Level.zero()}) ==
             forall(:x, sort(0), const(:Box, [1]))
  end

  test "normalization compares equivalent normalized levels" do
    u = Level.param(:u)
    left = sort(Level.max(u, u))
    right = sort(u)

    assert Normalize.defeq?(Env.new(), left, right)
  end
end
