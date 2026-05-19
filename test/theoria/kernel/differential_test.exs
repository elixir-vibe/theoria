defmodule Theoria.Kernel.DifferentialTest do
  use ExUnit.Case, async: true

  alias Theoria.Kernel.Differential
  alias Theoria.Kernel.Reference
  alias Theoria.Prelude
  alias Theoria.Term

  test "reference checker agrees with production kernel on the curated corpus" do
    {:ok, env} = Prelude.env()
    report = Differential.run(env)

    assert Differential.Report.ok?(report)
    assert report.infer_count > 0
    assert report.check_count > 0
    assert report.normalize_count > 0
    assert report.defeq_count > 0
    assert report.rejection_count > 0
    assert report.generated_term_count > 0
    assert report.generated_terms.total == report.generated_term_count
    assert report.generated_terms.size == 3
    assert report.generated_terms.max_terms == 128
    assert is_integer(report.timings.generated_term_ms)
    assert report.generated_term_families.bool > 0
    assert report.generated_term_families.nat_eq_rec > 0
    assert report.generated_term_families.nat_let > 0
    assert report.generated_term_families.bool_forall > 0
    assert report.generated_term_families.bool_refl > 0
    assert report.generated_term_families.bool_eq_rec > 0
    assert report.generated_term_families.bool_beta > 0
    assert report.generated_term_families.nat_beta > 0
    assert report.environment_count > 0
    assert report.environment_replay_count > 0
    assert report.environment_normalize_count > 0
    assert report.environment_report.total == report.environment_count
    assert report.invalid_environment_count > 0
    assert report.theorem_count > 0
    assert report.theorem_modules != []
    assert report.theorem_replay_count > 0
    assert report.generated_artifact_count > 0
    assert report.indexed_artifact_count > 0
    assert report.proof_strategy_counts.refl == report.generated_artifact_count
    assert report.proof_strategy_counts.recursor_iota_refl == report.indexed_artifact_count

    assert report.proof_strategies.total ==
             report.generated_artifact_count + report.indexed_artifact_count

    assert report.replay_count > 0
    assert report.artifact_replay_count > 0
  end

  test "reference checker covers let terms" do
    {:ok, env} = Prelude.env()
    term = Term.let(:x, Term.const(:Bool), Term.const(true), Term.bvar(0))

    assert {:ok, Term.const(:Bool)} == Reference.infer(env, term)
  end
end
