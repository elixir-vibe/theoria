defmodule Theoria.DocsTest do
  use ExUnit.Case, async: true

  test "public documentation extras stay wired into ExDoc" do
    extras = Theoria.MixProject.project() |> Keyword.fetch!(:docs) |> Keyword.fetch!(:extras)

    for path <- [
          "docs/public_api.md",
          "docs/assurance.md",
          "docs/release_0_8.md",
          "docs/release_0_8_checklist.md",
          "docs/theorem_modules.md",
          "docs/equations.md"
        ] do
      assert path in extras
    end
  end

  test "README links to the public API guide" do
    readme = File.read!("README.md")

    assert readme =~ "docs/public_api.md"
  end
end
