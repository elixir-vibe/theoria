defmodule Theoria.TheoremEnvTest do
  use ExUnit.Case, async: true

  alias Theoria.Env
  alias Theoria.Env.Constant
  alias Theoria.Kernel
  alias Theoria.Library.Logic
  alias Theoria.Theorem

  import Theoria.Term

  defmodule Proofs do
    use Theoria.DSL

    theorem :truth do
      type do
        term do
          true_prop()
        end
      end

      proof do
        term do
          const(:true_intro)
        end
      end
    end

    theorem :truth_again do
      type do
        term do
          true_prop()
        end
      end

      proof do
        term do
          const(:truth)
        end
      end
    end
  end

  test "adds a checked theorem to an environment as opaque" do
    {:ok, env} = Logic.env()
    assert {:ok, theorem} = Proofs.truth_theorem(env)

    assert {:ok, env} = Theorem.add_to_env(env, theorem)
    assert {:ok, %Constant{kind: :theorem, reducible?: false}} = Env.fetch(env, :truth)
  end

  test "checks and installs theorem modules in order" do
    {:ok, env} = Logic.env()

    assert {:error, error} = Proofs.truth_again_theorem(env)
    assert error.reason == :unknown_constant

    assert {:ok, env, theorems} = Theorem.add_all_to_env(Proofs, env)
    assert Enum.map(theorems, & &1.name) == [:truth, :truth_again]
    assert {:ok, %Constant{kind: :theorem, reducible?: false}} = Env.fetch(env, :truth_again)
  end

  test "reports axioms used by a checked theorem" do
    {:ok, env} = Logic.env()
    {:ok, env} = Kernel.add_axiom(env, :assumed_truth, const(:True))
    theorem = %Theorem{name: :uses_axiom, type: const(:True), proof: const(:assumed_truth)}

    assert Theorem.axioms(env, theorem) == {:ok, MapSet.new([:assumed_truth])}
  end

  test "reports transitive axioms through theorem constants" do
    {:ok, env} = Logic.env()
    {:ok, env} = Kernel.add_axiom(env, :assumed_truth, const(:True))
    {:ok, env} = Kernel.add_theorem(env, :first, const(:True), const(:assumed_truth))
    theorem = %Theorem{name: :second, type: const(:True), proof: const(:first)}

    assert Theorem.axioms(env, theorem) == {:ok, MapSet.new([:assumed_truth])}
  end
end
