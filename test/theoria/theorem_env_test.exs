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

  test "installs universe-polymorphic theorem declarations" do
    theorem = %Theorem{
      name: :poly_id,
      type: forall(:a, sort(Theoria.Level.param(:u)), arrow(bvar(0), bvar(0))),
      proof: lam(:a, sort(Theoria.Level.param(:u)), lam(:x, bvar(0), bvar(0))),
      universe_params: [:u]
    }

    assert {:ok, env} = Theorem.add_to_env(Env.new(), theorem)
    assert {:ok, %Constant{kind: :theorem, universe_params: [:u]}} = Env.fetch(env, :poly_id)
    assert {:ok, _type} = Kernel.infer(env, const(:poly_id, [1]))
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
