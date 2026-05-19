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
    assert output =~ "✓ environment cases:"
    assert output =~ "environment replay checks:"
    assert output =~ "environment normalize checks:"
    assert output =~ "✓ invalid environment checks:"
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

  test "rejects invalid generated term and environment bounds" do
    Mix.Task.clear()

    assert_raise Mix.Error, ~r/invalid --generated-size/, fn ->
      capture_io(fn -> Check.run(["--generated-size", "-1"]) end)
    end

    Mix.Task.clear()

    assert_raise Mix.Error, ~r/invalid --generated-max-terms/, fn ->
      capture_io(fn -> Check.run(["--generated-max-terms", "0"]) end)
    end

    Mix.Task.clear()

    assert_raise Mix.Error, ~r/invalid --environment-depth/, fn ->
      capture_io(fn -> Check.run(["--environment-depth", "0"]) end)
    end
  end

  test "accepts generated term bounds" do
    Mix.Task.clear()

    output =
      capture_io(fn ->
        Check.run([
          "--generated-size",
          "1",
          "--generated-max-terms",
          "4",
          "--environment-depth",
          "2",
          "--verbose"
        ])
      end)

    assert output =~ "✓ generated term checks: 39"
    assert output =~ "generated_terms=39 size=1 max_terms=4"
    assert output =~ "environment_cases=4 replay="
  end

  test "prints verbose report" do
    Mix.Task.clear()

    output =
      capture_io(fn ->
        Check.run(["--verbose"])
      end)

    assert output =~ "verbose:"
    assert output =~ "generated_terms="
    assert output =~ "environment_cases="
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
    assert output =~ "\"environment_cases\""
    assert output =~ "\"environment_replay_checks\""
    assert output =~ "\"environment_normalize_checks\""
    assert output =~ "\"environment_report\""
    assert output =~ "\"invalid_environment_checks\""
    assert output =~ "\"generated_artifact_checks\""
    assert output =~ "\"indexed_artifact_checks\""
    assert output =~ "\"proof_strategy_counts\""
    assert output =~ "\"proof_strategies\""
    assert output =~ "\"replay_checks\""
    assert output =~ "\"artifact_replay_checks\""
    assert output =~ "\"generated_artifact_replay_checks\""
    assert output =~ "\"timings\""
    assert output =~ "\"generated_term_ms\""
    assert output =~ "\"total_checks\""
    assert output =~ "\"failures\":[]"
  end

  test "prints structured JSON report shape" do
    Mix.Task.clear()

    output =
      capture_io(fn ->
        Check.run(["--json", "--generated-size", "1", "--generated-max-terms", "4"])
      end)

    report = Jason.decode!(output)

    assert report["generated_terms"]["total"] == 39
    assert report["generated_terms"]["size"] == 1
    assert report["generated_terms"]["max_terms"] == 4
    assert report["generated_terms"]["families"]["bool_beta"] == 4
    assert report["generated_terms"]["families"]["nat_beta"] == 3
    assert is_integer(report["timings"]["generated_term_ms"])
    assert report["environment_cases"] == 4
    assert report["environment_report"]["total"] == 4
    assert length(report["environment_report"]["cases"]) == 4
    assert report["environment_replay_checks"] > 0
    assert report["environment_normalize_checks"] > 0
    assert report["invalid_environment_checks"] == 3
    assert report["proof_strategies"]["total"] == 40
    assert report["proof_strategies"]["counts"]["refl"] == 38
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
