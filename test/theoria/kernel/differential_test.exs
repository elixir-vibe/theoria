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
  end

  test "reference checker reports unsupported terms explicitly" do
    {:ok, env} = Prelude.env()
    unsupported = Term.let(:x, Term.const(:Bool), Term.const(true), Term.bvar(0))

    assert {:error, %{reason: :unsupported_reference_term}} = Reference.infer(env, unsupported)
  end
end
