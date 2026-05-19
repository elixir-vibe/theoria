defmodule Mix.Tasks.Theoria.Kernel.CheckTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Mix.Tasks.Theoria.Kernel.Check

  test "runs kernel differential checks" do
    Mix.Task.clear()

    output =
      capture_io(fn ->
        Check.run([])
      end)

    assert output =~ "Kernel differential checks"
    assert output =~ "✓ infer checks:"
    assert output =~ "✓ check checks:"
    assert output =~ "✓ normalize checks:"
    assert output =~ "✓ defeq checks:"
    assert output =~ "✓ rejection checks:"
    assert output =~ "✓ theorem checks:"
    assert output =~ "✓ generated artifact checks:"
  end

  test "prints JSON report" do
    Mix.Task.clear()

    output =
      capture_io(fn ->
        Check.run(["--json"])
      end)

    assert output =~ "\"infer_checks\""
    assert output =~ "\"normalize_checks\""
    assert output =~ "\"theorem_checks\""
    assert output =~ "\"rejection_checks\""
    assert output =~ "\"generated_artifact_checks\""
    assert output =~ "\"failures\":[]"
  end
end
