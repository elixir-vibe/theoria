defmodule Theoria.Kernel.ReferenceReplayTest do
  use ExUnit.Case, async: true

  alias Theoria.Env
  alias Theoria.Kernel.Reference.Replay
  alias Theoria.Kernel.Reference.Replay.Failure
  alias Theoria.Term

  test "reports structured replay failures with dependency context" do
    env =
      Env.new()
      |> Env.put_constant(:Bad, Term.const(:Missing))

    assert %Replay.Report{checked: 0, skipped: 0, failures: [%Failure{} = failure]} =
             Replay.run(env)

    assert failure.name == :Bad
    assert failure.phase == :type
    assert failure.declaration_kind == :constant
    assert failure.direct_dependencies == [:Missing]
    assert failure.transitive_dependencies == [:Missing]
    assert failure.missing_dependencies == [:Missing]
    assert failure.dependency_path == [:Missing]
    assert failure.checked_before_failure == []
    assert failure.pending_after_failure == []
    assert match?(%Theoria.Error{}, failure.reason)
  end

  test "reports transitive dependency context" do
    env =
      Env.new()
      |> Env.put_axiom(:A, Term.sort(0))
      |> Env.put_axiom(:B, Term.const(:A))
      |> Env.put_constant(:Bad, Term.const(:B))

    assert %Replay.Report{failures: [%Failure{} = failure]} = Replay.run(env)

    assert failure.name == :Bad
    assert failure.direct_dependencies == [:B]
    assert failure.transitive_dependencies == [:A, :B]
    assert failure.missing_dependencies == []
    assert failure.dependency_path == []
    assert failure.checked_before_failure == [:A, :B]
    assert failure.pending_after_failure == []
  end

  test "reports dependency path and pending replay context" do
    env =
      Env.new()
      |> Env.put_axiom(:Root, Term.sort(0))
      |> Env.put_constant(:Middle, Term.const(:Missing))
      |> Env.put_constant(:Bad, Term.const(:Middle))
      |> Env.put_axiom(:Pending, Term.sort(0))

    assert %Replay.Report{failures: [%Failure{} = failure]} = Replay.run(env)

    assert failure.name == :Middle
    assert failure.dependency_path == [:Missing]
    assert failure.checked_before_failure == [:Root]
    assert failure.pending_after_failure == [:Bad, :Pending]
  end
end
