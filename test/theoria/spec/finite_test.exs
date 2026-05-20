defmodule Theoria.Spec.FiniteTest do
  use ExUnit.Case, async: true

  alias Theoria.Spec.Finite

  test "normalizes and compares finite collections" do
    assert MapSet.equal?(Finite.set([:b, :a, :a]), MapSet.new([:a, :b]))
    assert Finite.member?([:a, :b], :a)
    assert Finite.subset?([:a], [:a, :b])
    refute Finite.subset?([:c], [:a, :b])
    assert Finite.difference([:c, :a], [:a, :b]) == [:c]
  end

  test "builds subset claims" do
    valid = Finite.subset_claim([:a], [:a, :b])
    assert Finite.SubsetClaim.valid?(valid)
    assert valid.missing == []

    invalid = Finite.subset_claim([:a, :c], [:a, :b])
    refute Finite.SubsetClaim.valid?(invalid)
    assert invalid.missing == [:c]
    assert Jason.encode!(invalid) =~ "\"valid\":false"
  end

  test "builds no-new claims" do
    valid = Finite.no_new_claim([:a, :b], [:a])
    assert Finite.NoNewClaim.valid?(valid)
    assert valid.added == []

    invalid = Finite.no_new_claim([:a], [:a, :b])
    refute Finite.NoNewClaim.valid?(invalid)
    assert invalid.added == [:b]
    assert Jason.encode!(invalid) =~ "\"added\":[\":b\"]"
  end
end
