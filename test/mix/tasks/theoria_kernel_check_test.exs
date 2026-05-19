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
    assert output =~ "✓ generated term checks:"
    assert output =~ "bool:"
    assert output =~ "nat_eq_rec:"
    assert output =~ "✓ theorem checks:"
    assert output =~ "✓ theorem replay checks:"
    assert output =~ "✓ generated artifact checks:"
    assert output =~ "✓ indexed artifact checks:"
    assert output =~ "proof strategies:"
    assert output =~ "refl:"
    assert output =~ "recursor_iota_refl:"
    assert output =~ "✓ replay checks:"
    assert output =~ "- replay skipped:"
    assert output =~ "✓ artifact replay checks:"
    assert output =~ "generated artifact replay checks:"
    assert output =~ "indexed artifact replay checks:"
    assert output =~ "- artifact replay skipped:"
  end

  test "accepts generated term bounds" do
    Mix.Task.clear()

    output =
      capture_io(fn ->
        Check.run(["--generated-size", "1", "--generated-max-terms", "4", "--verbose"])
      end)

    assert output =~ "✓ generated term checks: 39"
    assert output =~ "generated_terms=39 size=1 max_terms=4"
  end

  test "prints verbose report" do
    Mix.Task.clear()

    output =
      capture_io(fn ->
        Check.run(["--verbose"])
      end)

    assert output =~ "verbose:"
    assert output =~ "generated_terms="
    assert output =~ "indexed_artifacts="
    assert output =~ "replay="
    assert output =~ "artifact_replay="
    assert output =~ "timings="
    assert output =~ "total_checks="
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
    assert output =~ "\"theorem_replay_checks\""
    assert output =~ "\"rejection_checks\""
    assert output =~ "\"generated_term_checks\""
    assert output =~ "\"generated_terms\""
    assert output =~ "\"families\""
    assert output =~ "\"max_terms\""
    assert output =~ "\"generated_artifact_checks\""
    assert output =~ "\"indexed_artifact_checks\""
    assert output =~ "\"proof_strategy_counts\""
    assert output =~ "\"proof_strategies\""
    assert output =~ "\"replay_checks\""
    assert output =~ "\"artifact_replay_checks\""
    assert output =~ "\"generated_artifact_replay_checks\""
    assert output =~ "\"timings\""
    assert output =~ "\"total_checks\""
    assert output =~ "\"failures\":[]"
  end

  test "prints explanation report" do
    Mix.Task.clear()

    output =
      capture_io(fn ->
        Check.run(["--explain"])
      end)

    assert output =~ "explain:"
    assert output =~ "reference_replay"
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

  test "prints JSON explanation report" do
    Mix.Task.clear()

    output =
      capture_io(fn ->
        Check.run(["--coverage", "--explain", "--json"])
      end)

    assert output =~ "\"explanation\""
    assert output =~ "\"trusted\""
    assert output =~ "\"boundary\""
  end
end
