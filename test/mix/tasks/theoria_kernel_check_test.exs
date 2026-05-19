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
    assert output =~ "✓ indexed artifact checks:"
    assert output =~ "✓ replay checks:"
    assert output =~ "- replay skipped:"
    assert output =~ "✓ artifact replay checks:"
    assert output =~ "generated artifact replay checks:"
    assert output =~ "indexed artifact replay checks:"
    assert output =~ "- artifact replay skipped:"
  end

  test "prints verbose report" do
    Mix.Task.clear()

    output =
      capture_io(fn ->
        Check.run(["--verbose"])
      end)

    assert output =~ "verbose:"
    assert output =~ "indexed_artifacts="
    assert output =~ "replay="
    assert output =~ "artifact_replay="
  end

  test "prints coverage report" do
    Mix.Task.clear()

    output =
      capture_io(fn ->
        Check.run(["--coverage"])
      end)

    assert output =~ "coverage:"
    assert output =~ "supported_terms="
    assert output =~ "property_families="
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
    assert output =~ "\"indexed_artifact_checks\""
    assert output =~ "\"replay_checks\""
    assert output =~ "\"artifact_replay_checks\""
    assert output =~ "\"generated_artifact_replay_checks\""
    assert output =~ "\"failures\":[]"
  end

  test "prints JSON coverage report" do
    Mix.Task.clear()

    output =
      capture_io(fn ->
        Check.run(["--coverage", "--json"])
      end)

    assert output =~ "\"report\""
    assert output =~ "\"coverage\""
    assert output =~ "\"artifact_replay\""
    assert output =~ "\"supported_term_constructors\""
  end
end
