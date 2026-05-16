defmodule Theoria.Kernel.TrustReportTest do
  use ExUnit.Case, async: true

  alias Theoria.Env
  alias Theoria.Kernel
  alias Theoria.Library.Logic

  import Theoria.Term

  test "reports declaration kind and dependency classes" do
    {:ok, env} = Logic.env()
    {:ok, env} = Kernel.add_axiom(env, :assumed_truth, const(:True))
    {:ok, env} = Kernel.add_theorem(env, :first, const(:True), const(:assumed_truth))
    {:ok, env} = Kernel.add_theorem(env, :second, const(:True), const(:first))

    assert {:ok, report} = Kernel.trust_report(env, :second)

    assert report.name == :second
    assert report.kind == :theorem
    assert report.direct_dependencies == MapSet.new([:True, :first])
    assert report.axioms == MapSet.new([:assumed_truth])
    assert MapSet.member?(report.primitive_dependencies, :True)
    assert MapSet.subset?(MapSet.new([:first]), report.theorem_dependencies)
  end

  test "reports primitive constants without axioms" do
    {:ok, env} = Kernel.add_constant(Env.new(), :A, sort(0))

    assert {:ok, report} = Kernel.trust_report(env, :A)
    assert report.kind == :constant
    assert report.direct_dependencies == MapSet.new()
    assert report.axioms == MapSet.new()
  end

  test "unknown declaration trust report fails" do
    assert {:error, error} = Kernel.trust_report(Env.new(), :missing)
    assert error.reason == :unknown_constant
  end
end
