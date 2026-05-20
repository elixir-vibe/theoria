defmodule Theoria.EquationReportTest do
  use ExUnit.Case, async: true

  alias Theoria.Equation.Identity
  alias Theoria.Equation.Info
  alias Theoria.Equation.Report
  alias Theoria.Prelude

  test "report and entry expose accessors" do
    {:ok, env} = Prelude.env()
    {:ok, info} = Info.fetch(env, :nat_add)

    report = Report.from_equations(env, [info])
    assert Report.registry_entries(report) == 5
    assert [entry] = Report.entries(report)
    assert Report.Entry.definition(entry) == :nat_add
    assert Identity.equation(:nat_add, :succ) in Report.Entry.identities(entry)
    assert Report.Entry.unfold_identity(entry) == Identity.unfold(:nat_add)

    assert Identity.matcher_equation(:nat_add_match_1, :succ) in Report.Entry.matcher_identities(
             entry
           )

    assert Report.Entry.realized(entry) == 0
  end
end
