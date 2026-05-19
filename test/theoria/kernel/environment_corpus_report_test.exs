defmodule Theoria.Kernel.EnvironmentCorpusReportTest do
  use ExUnit.Case, async: true

  alias Theoria.Kernel.EnvironmentCorpus
  alias Theoria.Kernel.EnvironmentCorpus.Report

  test "report accessors expose totals and named cases" do
    report =
      EnvironmentCorpus.cases()
      |> Enum.map(fn corpus_case ->
        %Report.Case{name: corpus_case.name, replay_checks: 1, normalize_checks: 2, failures: []}
      end)
      |> Report.new()

    assert Report.total(report) == 4
    assert Report.replay_checks(report) == 4
    assert Report.normalize_checks(report) == 8

    assert Report.case_names(report) == [
             :definition_chain,
             :let_chain,
             :theorem_chain,
             :universe_polymorphic_chain
           ]

    assert %Report.Case{name: :definition_chain} = Report.case(report, :definition_chain)
    assert Report.case_count(report, :definition_chain) == 1
    assert Report.case_count(report, :missing) == 0
  end
end
