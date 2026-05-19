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
    assert match?(%Theoria.Error{}, failure.reason)
  end
end
