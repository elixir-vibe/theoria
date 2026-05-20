defmodule Theoria.Theorem.ReportTest do
  use ExUnit.Case, async: true

  alias Theoria.Theorem.ModuleReport
  alias Theoria.Theorem.Report

  test "module report exposes accessors and encodes as JSON" do
    report = %ModuleReport{
      module: SampleProofs,
      theorem_names: [:truth],
      theorem_count: 1,
      installed?: true,
      axioms: []
    }

    assert ModuleReport.module(report) == SampleProofs
    assert ModuleReport.theorem_names(report) == [:truth]
    assert ModuleReport.theorem_count(report) == 1
    assert ModuleReport.installed?(report)
    assert ModuleReport.axioms(report) == []
    assert Jason.encode!(report) =~ "SampleProofs"
  end

  test "run report totals module reports" do
    module_report = %ModuleReport{
      module: SampleProofs,
      theorem_names: [:truth],
      theorem_count: 1,
      installed?: false,
      axioms: nil
    }

    report = Report.new([module_report])

    assert Report.modules(report) == [module_report]
    assert Report.total(report) == 1
  end
end
