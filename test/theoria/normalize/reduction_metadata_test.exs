defmodule Theoria.Normalize.ReductionMetadataTest do
  use ExUnit.Case, async: true

  alias Theoria.Env
  alias Theoria.Env.Constant
  alias Theoria.Env.Reduction
  alias Theoria.Kernel
  alias Theoria.Library.Bool
  alias Theoria.Library.Nat
  alias Theoria.Normalize

  import Theoria.Term

  test "primitive reduction metadata drives recursor computation" do
    {:ok, env} = Bool.env()

    term =
      const(:bool_rec, [1])
      |> app(const(:Bool))
      |> app(const(false))
      |> app(const(true))
      |> app(const(false))

    assert Normalize.defeq?(env, term, const(true))
  end

  test "legacy reduction metadata remains supported" do
    {:ok, env} = Bool.env()
    env = put_reduction(env, :bool_rec, %Reduction.BoolRec{})

    term =
      const(:bool_rec, [1])
      |> app(const(:Bool))
      |> app(const(false))
      |> app(const(true))
      |> app(const(false))

    assert Normalize.defeq?(env, term, const(true))
  end

  test "recursor without reduction metadata remains stuck" do
    {:ok, env} = Bool.env()
    env = remove_reduction(env, :bool_rec)

    term =
      const(:bool_rec, [1])
      |> app(const(:Bool))
      |> app(const(false))
      |> app(const(true))
      |> app(const(false))

    assert Normalize.normalize(env, term) == {:ok, term}
  end

  test "environment validation preserves reduction metadata" do
    {:ok, env} = Nat.env()

    assert {:ok, checked_env} = Kernel.validate_env(env)

    assert {:ok,
            %Constant{
              reduction: %Reduction.Recursor{
                inductive: :Nat,
                major_position: 3,
                constructors: constructors
              }
            }} = Env.fetch(checked_env, :nat_ind)

    assert Enum.map(constructors, & &1.name) == [:zero, :succ]

    assert %Theoria.Env.Recursor{rules: rules, num_motives: 1, num_minors: 2} =
             checked_env.constants.nat_ind.metadata

    assert Enum.map(rules, &{&1.constructor, &1.field_count}) == [zero: 0, succ: 1]
  end

  test "environment validation rejects malformed reduction metadata" do
    {:ok, env} = Nat.env()
    env = put_reduction(env, :nat_rec, :not_a_reduction)

    assert {:error, error} = Kernel.validate_env(env)
    assert error.reason == :invalid_reduction
  end

  defp remove_reduction(env, name), do: put_reduction(env, name, nil)

  defp put_reduction(%Env{constants: constants} = env, name, reduction) do
    %Constant{} = constant = Map.fetch!(constants, name)
    %Env{env | constants: Map.put(constants, name, %Constant{constant | reduction: reduction})}
  end
end
