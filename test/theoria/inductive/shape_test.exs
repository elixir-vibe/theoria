defmodule Theoria.Inductive.ShapeTest do
  use ExUnit.Case, async: true

  alias Theoria.Env
  alias Theoria.Inductive
  alias Theoria.Inductive.{Constructor, Spec}
  alias Theoria.Library.{Bool, List, Nat}

  import Theoria.Term

  test "classifies built-in inductive shapes" do
    assert Inductive.shape(without_recursors(Bool.inductive_spec())) == :bool_like
    assert Inductive.shape(without_recursors(Nat.inductive_spec())) == :nat_like
    assert Inductive.shape(without_recursors(List.inductive_spec())) == :list_like
  end

  test "classifies unsupported specs as unknown" do
    spec = %Spec{
      name: :Unit,
      type: sort(1),
      constructors: [%Constructor{name: :unit, type: const(:Unit)}]
    }

    assert Inductive.shape(spec) == :unknown
  end

  test "completes known shapes with generated eliminators" do
    spec = without_recursors(Nat.inductive_spec())

    assert {:ok, completed} = Inductive.complete(spec)
    assert Enum.map(completed.recursors, & &1.name) == [:nat_rec, :nat_ind]
    assert Inductive.validate(completed) == :ok
  end

  test "completed specs install through kernel admission" do
    spec = without_recursors(Bool.inductive_spec())

    assert {:ok, completed} = Inductive.complete(spec)
    assert {:ok, env} = Theoria.Kernel.add_inductive(Env.new(), completed)
    assert Inductive.verify_env(env, completed) == :ok
  end

  test "unknown shapes cannot be completed" do
    spec = %Spec{
      name: :Unit,
      type: sort(1),
      constructors: [%Constructor{name: :unit, type: const(:Unit)}]
    }

    assert {:error, error} = Inductive.complete(spec)
    assert error.reason == :invalid_inductive
    assert Keyword.fetch!(error.details, :problem) == :unknown_inductive_shape
  end

  defp without_recursors(%Spec{} = spec), do: %Spec{spec | recursors: []}
end
