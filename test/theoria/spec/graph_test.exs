defmodule Theoria.Spec.GraphTest do
  use ExUnit.Case, async: true

  alias Theoria.Spec.Graph

  test "validates finite graph paths" do
    graph = Graph.new([{:a, :b}, {:b, :c}])

    assert MapSet.equal?(Graph.nodes(graph), MapSet.new([:a, :b, :c]))
    assert Graph.edge?(graph, :a, :b)
    refute Graph.edge?(graph, :a, :c)
    assert Graph.path?(graph, [:a, :b, :c])
    refute Graph.path?(graph, [:a, :c])
  end

  test "builds path claims with diagnostics" do
    graph = Graph.new([{:a, :b}, {:b, :c}])

    valid = Graph.path_claim(graph, :a, :c, [:a, :b, :c])
    assert Graph.PathClaim.valid?(valid)
    assert Graph.PathClaim.reason(valid) == nil

    wrong_start = Graph.path_claim(graph, :a, :c, [:b, :c])
    refute Graph.PathClaim.valid?(wrong_start)
    assert Graph.PathClaim.reason(wrong_start) == :wrong_start

    missing = Graph.path_claim(graph, :a, :c, [:a, :c])
    refute Graph.PathClaim.valid?(missing)
    assert Graph.PathClaim.reason(missing) == :missing_edge

    assert Jason.encode!(valid) =~ "\"valid\":true"
  end
end
