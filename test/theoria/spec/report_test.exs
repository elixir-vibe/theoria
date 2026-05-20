defmodule Theoria.Spec.ReportTest do
  use ExUnit.Case, async: true

  alias Theoria.Spec.Claim
  alias Theoria.Spec.Effect
  alias Theoria.Spec.Finite
  alias Theoria.Spec.Graph
  alias Theoria.Spec.Report

  test "normalizes claim protocol across spec vocabularies" do
    graph = Graph.new([{:a, :b}])
    path = Graph.path_claim(graph, :a, :b, [:a, :b])
    finite = Finite.no_new_claim([:a], [:a, :b])
    [effect] = Effect.deltas([:pure], [:write])

    assert Claim.kind(path) == :graph_path
    assert Claim.valid?(path)
    assert Claim.reason(path) == nil

    assert Claim.kind(finite) == :finite_no_new
    refute Claim.valid?(finite)
    assert Claim.reason(finite) == {:added, [:b]}

    assert Claim.kind(effect) == :effect_delta
    refute Claim.valid?(effect)
    assert Claim.reason(effect) == {:stronger_effect, :pure, :write}
  end

  test "summarizes structural claims" do
    graph = Graph.new([{:a, :b}])

    claims = [
      Graph.path_claim(graph, :a, :b, [:a, :b]),
      Graph.path_claim(graph, :a, :b, [:a]),
      Finite.subset_claim([:x], [:x, :y])
    ]

    report = Report.new(claims)

    assert Report.claims(report) == claims
    assert Report.total(report) == 3
    assert Report.valid(report) == 2
    assert Report.invalid(report) == 1
    assert Report.kinds(report) == %{finite_subset: 1, graph_path: 2}

    assert {:ok, json} = Jason.encode!(report) |> Jason.decode()
    assert json["total"] == 3
    assert json["valid"] == 2
    assert json["invalid"] == 1
  end
end
