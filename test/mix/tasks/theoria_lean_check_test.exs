defmodule Mix.Tasks.Theoria.Lean.CheckTest do
  use ExUnit.Case, async: true

  alias Mix.Tasks.Theoria.Lean.Check

  test "parses single --only category" do
    assert Check.__parse_args__(["--only", "bool"])[:only] == [:bool]
  end

  test "parses comma-separated --only categories" do
    assert Check.__parse_args__(["--only", "bool,nat"])[:only] == [:bool, :nat]
  end

  test "parses vec category" do
    assert Check.__parse_args__(["--only", "vec"])[:only] == [:vec]
  end

  test "rejects invalid --only categories" do
    assert_raise Mix.Error, ~r/invalid --only value: wat/, fn ->
      Check.__parse_args__(["--only", "wat"])
    end
  end
end
