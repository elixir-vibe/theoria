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
    assert report.theorem_count > 0
    assert report.generated_artifact_count > 0
  end

  test "reference checker covers let terms" do
    {:ok, env} = Prelude.env()
    term = Term.let(:x, Term.const(:Bool), Term.const(true), Term.bvar(0))

    assert {:ok, Term.const(:Bool)} == Reference.infer(env, term)
  end
end
