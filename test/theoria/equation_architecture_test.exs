defmodule Theoria.EquationArchitectureTest do
  use ExUnit.Case, async: true

  @equation_path Path.expand("../../lib/theoria/equation", __DIR__)

  test "libraries do not own schema or matcher construction helpers" do
    library_sources =
      Path.wildcard(Path.expand("../../lib/theoria/library/**/*.ex", __DIR__))
      |> Enum.map(&{&1, File.read!(&1)})

    forbidden = [
      "bool_schema",
      "nat_add_schema",
      "schema_for",
      "bool_matcher",
      "nat_matcher",
      "list_matcher",
      "Matcher.Info.new",
      "MatcherInfo.new",
      "Schema.new"
    ]

    for {path, source} <- library_sources, term <- forbidden do
      refute source =~ term, "#{path} must not contain #{term}"
    end
  end

  test "equation registry and descriptor layers stay family-policy free where required" do
    assert_no_source("extension.ex", [":bool", ":nat", ":list", "Theoria.Library"])
    assert_no_source("eqns.ex", ["compile_definition", "Schema.Builder", "Theoria.Library"])

    assert_no_source("matcher/eqns.ex", [
      "compile_definition",
      "Schema.Builder",
      "Theoria.Library"
    ])
  end

  test "matcher generation layers do not depend on kernel or libraries" do
    for file <- ["matcher/descriptor.ex", "matcher/type.ex", "matcher/spec.ex"] do
      assert_no_source(file, ["Theoria.Kernel", "Theoria.Library"])
    end
  end

  test "compiler owns schema builder but not concrete definition names" do
    assert_no_source("compiler.ex", [
      "bool_not",
      "bool_and",
      "bool_or",
      "nat_add",
      "list_length",
      "list_append"
    ])
  end

  test "indexed statement planners do not silently fall back to placeholder equality metadata" do
    for file <- ["matcher/statement.ex", "matcher/statement/vec.ex"] do
      assert_no_source(file, ["equation.equality_type"])
    end
  end

  defp assert_no_source(file, forbidden) do
    path = Path.join(@equation_path, file)
    source = File.read!(path)

    for term <- forbidden do
      refute source =~ term, "#{path} must not contain #{term}"
    end
  end
end
