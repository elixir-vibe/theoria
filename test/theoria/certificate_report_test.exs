defmodule Theoria.CertificateReportTest do
  use ExUnit.Case, async: true

  alias Theoria.Certificate
  alias Theoria.Certificate.Report
  alias Theoria.Obligation
  alias Theoria.Term

  test "summarizes certificate statuses" do
    goal = Term.eq(Term.sort(1), Term.sort(0), Term.sort(0))
    proof = Term.refl(Term.sort(0))
    checked = Certificate.checked(Obligation.new(:ok, goal, proof: proof))
    failed = Certificate.failed(Obligation.new(:bad, goal, proof: Term.sort(0)), :type_mismatch)
    unchecked = Certificate.unchecked(Obligation.new(:missing, goal), :missing_proof)

    report = Report.new([checked, failed, unchecked])

    assert Report.certificates(report) == [checked, failed, unchecked]
    assert Report.total(report) == 3
    assert Report.checked(report) == 1
    assert Report.failed(report) == 1
    assert Report.unchecked(report) == 1

    assert {:ok, json} = Jason.encode!(report) |> Jason.decode()
    assert json["total"] == 3
    assert json["checked"] == 1
    assert json["failed"] == 1
    assert json["unchecked"] == 1
  end
end
