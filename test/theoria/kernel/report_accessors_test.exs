defmodule Theoria.Kernel.ReportAccessorsTest do
  use ExUnit.Case, async: true

  alias Theoria.Kernel.GeneratedTerm.Report, as: GeneratedTermReport
  alias Theoria.Kernel.MetadataReplayReport
  alias Theoria.Kernel.TheoremModuleReport

  test "metadata replay report exposes accessor functions" do
    report = MetadataReplayReport.new([{:prelude, 2, []}, {:generated, 3, [:failed]}])

    assert MetadataReplayReport.checked(report) == 5
    assert MetadataReplayReport.sources(report) == %{generated: 3, prelude: 2}
    assert MetadataReplayReport.source_count(report, :prelude) == 2
    assert MetadataReplayReport.failures(report) == [:failed]
    assert MetadataReplayReport.failure_count(report) == 1
  end

  test "generated term report exposes bound accessors" do
    report = %GeneratedTermReport{total: 2, families: %{bool: 2}, size: 1, max_terms: 4}

    assert GeneratedTermReport.total(report) == 2
    assert GeneratedTermReport.families(report) == %{bool: 2}
    assert GeneratedTermReport.family_count(report, :bool) == 2
    assert GeneratedTermReport.size(report) == 1
    assert GeneratedTermReport.max_terms(report) == 4
  end

  test "theorem module report exposes accessor functions" do
    report = %TheoremModuleReport{
      module: ExampleProofs,
      checks: 2,
      replay_checks: 2,
      replay_skipped: 0,
      failures: []
    }

    assert TheoremModuleReport.module(report) == ExampleProofs
    assert TheoremModuleReport.checks(report) == 2
    assert TheoremModuleReport.replay_checks(report) == 2
    assert TheoremModuleReport.replay_skipped(report) == 0
    assert TheoremModuleReport.failures(report) == []
    assert TheoremModuleReport.ok?(report)
    assert TheoremModuleReport.total_checks(report) == 4
  end
end
