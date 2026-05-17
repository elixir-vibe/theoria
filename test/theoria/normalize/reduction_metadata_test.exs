defmodule Theoria.Normalize.ReductionMetadataTest do
  use ExUnit.Case, async: true

  alias Theoria.Env
  alias Theoria.Env.Constant
  alias Theoria.Env.Reduction
  alias Theoria.Kernel
  alias Theoria.Library.Bool
  alias Theoria.Library.Nat
  alias Theoria.Library.Vec
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

    assert Enum.map(rules, &{&1.constructor, &1.field_count, &1.index_patterns}) == [
             {:zero, 0, []},
             {:succ, 1, []}
           ]

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

  test "recursor rule index patterns must match recursor indices" do
    {:ok, env} = Bool.env()

    env =
      put_metadata(env, :bool_rec, fn %Theoria.Env.Recursor{} = recursor ->
        %Theoria.Env.RecursorRule{} =
          true_rule = Enum.find(recursor.rules, &(&1.constructor == true))

        bad_rule = %Theoria.Env.RecursorRule{true_rule | index_patterns: [const(:Bool)]}

        %Theoria.Env.Recursor{
          recursor
          | rules: [bad_rule | Enum.reject(recursor.rules, &(&1.constructor == true))]
        }
      end)

    assert {:error, error} = Kernel.validate_env(env)
    assert error.reason == :invalid_reduction
  end

  test "indexed recursor rule patterns must match constructor result indices" do
    {:ok, env} = Vec.env()

    env =
      put_metadata(env, :vec_ind, fn %Theoria.Env.Recursor{} = recursor ->
        %Theoria.Env.RecursorRule{} =
          nil_rule = Enum.find(recursor.rules, &(&1.constructor == :vec_nil))

        bad_rule = %Theoria.Env.RecursorRule{
          nil_rule
          | index_patterns: [app(const(:succ), const(:zero))]
        }

        %Theoria.Env.Recursor{
          recursor
          | rules: [bad_rule | Enum.reject(recursor.rules, &(&1.constructor == :vec_nil))]
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

  test "generated recursive recursor rule rhs terms infer as branch functions" do
    {:ok, env} = Nat.env()

    assert {:ok, %Constant{metadata: %Theoria.Env.Recursor{rules: rules}}} =
             Env.fetch(env, :nat_rec)

    assert Enum.all?(rules, fn rule ->
             match?({:ok, %Theoria.Term.Forall{}}, Kernel.infer(env, rule.rhs))
           end)
  end

  test "recursor rule rhs must have the expected prefix domains" do
    {:ok, env} = Bool.env()

    env =
      put_metadata(env, :bool_rec, fn %Theoria.Env.Recursor{} = recursor ->
        %Theoria.Env.RecursorRule{} =
          true_rule = Enum.find(recursor.rules, &(&1.constructor == true))

        bad_rule = %Theoria.Env.RecursorRule{
          true_rule
          | rhs: lam(:motive, sort(1), lam(:minor0, bvar(0), lam(:minor1, bvar(1), bvar(1))))
        }

        %Theoria.Env.Recursor{
          recursor
          | rules: [bad_rule | Enum.reject(recursor.rules, &(&1.constructor == true))]
        }
      end)

    assert {:error, error} = Kernel.validate_env(env)
    assert error.reason == :invalid_reduction
  end

  test "recursor rule rhs result must match constructor motive application" do
    {:ok, env} = Nat.env()

    env =
      put_metadata(env, :nat_ind, fn %Theoria.Env.Recursor{} = recursor ->
        %Theoria.Env.RecursorRule{} =
          succ_rule = Enum.find(recursor.rules, &(&1.constructor == :succ))

        u = Theoria.Level.param(:u)

        bad_rule = %Theoria.Env.RecursorRule{
          succ_rule
          | rhs:
              lam(
                :motive,
                arrow(const(:Nat), sort(u)),
                lam(
                  :minor0,
                  app(bvar(0), const(:zero)),
                  lam(
                    :minor1,
                    forall(
                      :arg0,
                      const(:Nat),
                      arrow(app(bvar(1), bvar(0)), app(bvar(2), app(const(:succ), bvar(0))))
                    ),
                    lam(
                      :field0,
                      const(:Nat),
                      const(:nat_ind, [u])
                      |> app(bvar(3))
                      |> app(bvar(2))
                      |> app(bvar(1))
                      |> app(bvar(0))
                    )
                  )
                )
              )
        }

        %Theoria.Env.Recursor{
          recursor
          | rules: [bad_rule | Enum.reject(recursor.rules, &(&1.constructor == :succ))]
        }
      end)

    assert {:error, error} = Kernel.validate_env(env)
    assert error.reason == :invalid_reduction
  end

  test "recursor rule rhs must have expected field domains" do
    {:ok, env} = Nat.env()

    env =
      put_metadata(env, :nat_rec, fn %Theoria.Env.Recursor{} = recursor ->
        %Theoria.Env.RecursorRule{} =
          succ_rule = Enum.find(recursor.rules, &(&1.constructor == :succ))

        bad_rule = %Theoria.Env.RecursorRule{
          succ_rule
          | rhs:
              lam(
                :motive,
                sort(Theoria.Level.param(:u)),
                lam(
                  :minor0,
                  bvar(0),
                  lam(
                    :minor1,
                    arrow(const(:Nat), arrow(bvar(1), bvar(2))),
                    lam(:field0, bvar(2), bvar(2))
                  )
                )
              )
        }

        %Theoria.Env.Recursor{
          recursor
          | rules: [bad_rule | Enum.reject(recursor.rules, &(&1.constructor == :succ))]
        }
      end)

    assert {:error, error} = Kernel.validate_env(env)
    assert error.reason == :invalid_reduction
  end

  test "recursor rule rhs must not have extra lambdas" do
    {:ok, env} = Bool.env()

    env =
      put_metadata(env, :bool_rec, fn %Theoria.Env.Recursor{} = recursor ->
        %Theoria.Env.RecursorRule{} =
          true_rule = Enum.find(recursor.rules, &(&1.constructor == true))

        bad_rule = %Theoria.Env.RecursorRule{true_rule | rhs: lam(:extra, sort(0), true_rule.rhs)}

        %Theoria.Env.Recursor{
          recursor
          | rules: [bad_rule | Enum.reject(recursor.rules, &(&1.constructor == true))]
        }
      end)

    assert {:error, error} = Kernel.validate_env(env)
    assert error.reason == :invalid_reduction
  end

  test "recursor rule rhs must infer as a branch function" do
    {:ok, env} = Bool.env()

    env =
      put_metadata(env, :bool_rec, fn %Theoria.Env.Recursor{} = recursor ->
        %Theoria.Env.RecursorRule{} =
          true_rule = Enum.find(recursor.rules, &(&1.constructor == true))

        bad_rule = %Theoria.Env.RecursorRule{true_rule | rhs: const(true)}

        %Theoria.Env.Recursor{
          recursor
          | rules: [bad_rule | Enum.reject(recursor.rules, &(&1.constructor == true))]
        }
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
