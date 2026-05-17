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
              reduction: %Reduction.Iota{},
              metadata: %Theoria.Env.Recursor{rules: rules, num_motives: 1, num_minors: 2}
            }} =
             Env.fetch(checked_env, :nat_ind)

    assert Enum.map(rules, &{&1.constructor, &1.field_count}) == [zero: 0, succ: 1]
    assert Enum.all?(rules, &match?(%Theoria.Term.Lam{}, &1.rhs))
  end

  test "recursor without recursor metadata remains stuck and fails validation" do
    {:ok, env} = Bool.env()
    env = put_metadata(env, :bool_rec, nil)

    term =
      const(:bool_rec, [1])
      |> app(const(:Bool))
      |> app(const(false))
      |> app(const(true))
      |> app(const(false))

    assert Normalize.normalize(env, term) == {:ok, term}
    assert {:error, error} = Kernel.validate_env(env)
    assert error.reason == :invalid_declaration
  end

  test "malformed recursor rule rhs fails validation" do
    {:ok, env} = Bool.env()

    env =
      put_metadata(env, :bool_rec, fn %Theoria.Env.Recursor{} = recursor ->
        %Theoria.Env.RecursorRule{} =
          true_rule = Enum.find(recursor.rules, &(&1.constructor == true))

        bad_rule = %Theoria.Env.RecursorRule{true_rule | rhs: bvar(99)}

        %Theoria.Env.Recursor{
          recursor
          | rules: [bad_rule | Enum.reject(recursor.rules, &(&1.constructor == true))]
        }
      end)

    assert {:error, error} = Kernel.validate_env(env)
    assert error.reason == :invalid_reduction
  end

  test "recursor rule coverage must match inductive constructors" do
    {:ok, env} = Bool.env()

    env =
      put_metadata(env, :bool_rec, fn %Theoria.Env.Recursor{} = recursor ->
        %Theoria.Env.RecursorRule{} =
          true_rule = Enum.find(recursor.rules, &(&1.constructor == true))

        %Theoria.Env.Recursor{recursor | rules: [true_rule, true_rule]}
      end)

    assert {:error, error} = Kernel.validate_env(env)
    assert error.reason == :invalid_reduction
  end

  test "recursor rule rhs universe params must be declared by the recursor" do
    {:ok, env} = Bool.env()

    env =
      put_metadata(env, :bool_rec, fn %Theoria.Env.Recursor{} = recursor ->
        %Theoria.Env.RecursorRule{} =
          true_rule = Enum.find(recursor.rules, &(&1.constructor == true))

        bad_rule = %Theoria.Env.RecursorRule{
          true_rule
          | rhs: const(true, [Theoria.Level.param(:missing)])
        }

        %Theoria.Env.Recursor{
          recursor
          | rules: [bad_rule | Enum.reject(recursor.rules, &(&1.constructor == true))]
        }
      end)

    assert {:error, error} = Kernel.validate_env(env)
    assert error.reason == :invalid_reduction
  end

  test "recursor rule rhs is authoritative" do
    {:ok, env} = Bool.env()

    env =
      put_metadata(env, :bool_rec, fn %Theoria.Env.Recursor{} = recursor ->
        %Theoria.Env.RecursorRule{} =
          false_rule = Enum.find(recursor.rules, &(&1.constructor == false))

        bad_rule = %Theoria.Env.RecursorRule{
          false_rule
          | rhs: lam(:a, sort(0), lam(:t, sort(0), lam(:f, sort(0), const(true))))
        }

        %Theoria.Env.Recursor{
          recursor
          | rules: [bad_rule | Enum.reject(recursor.rules, &(&1.constructor == false))]
        }
      end)

    term =
      const(:bool_rec, [1])
      |> app(const(:Bool))
      |> app(const(false))
      |> app(const(true))
      |> app(const(false))

    assert Normalize.defeq?(env, term, const(true))
  end

  test "environment validation rejects malformed reduction metadata" do
    {:ok, env} = Nat.env()
    env = put_reduction(env, :nat_rec, :not_a_reduction)

    assert {:error, error} = Kernel.validate_env(env)
    assert error.reason == :invalid_declaration
  end

  defp remove_reduction(env, name), do: put_reduction(env, name, nil)

  defp put_reduction(%Env{constants: constants} = env, name, reduction) do
    %Constant{} = constant = Map.fetch!(constants, name)
    %Env{env | constants: Map.put(constants, name, %Constant{constant | reduction: reduction})}
  end

  defp put_metadata(%Env{constants: constants} = env, name, metadata_or_fun) do
    %Constant{} = constant = Map.fetch!(constants, name)

    metadata =
      if is_function(metadata_or_fun, 1) do
        metadata_or_fun.(constant.metadata)
      else
        metadata_or_fun
      end

    %Env{env | constants: Map.put(constants, name, %Constant{constant | metadata: metadata})}
  end
end
