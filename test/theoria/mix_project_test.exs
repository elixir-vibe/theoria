defmodule Theoria.MixProjectTest do
  use ExUnit.Case, async: true

  test "ci uses native validation" do
    aliases = Theoria.MixProject.project() |> Keyword.fetch!(:aliases)
    ci = Keyword.fetch!(aliases, :ci)

    assert "theoria.validate" in ci
    refute "theoria.check" in ci
  end

  test "package files include public artifacts and exclude fixtures/tests" do
    package = Theoria.MixProject.project() |> Keyword.fetch!(:package)
    files = Keyword.fetch!(package, :files)

    assert "lib" in files
    assert "docs" in files
    assert "README.md" in files
    assert "CHANGELOG.md" in files
    assert "LICENSE" in files
    refute "fixtures" in files
    refute "test" in files
    refute "_build" in files
    refute "doc" in files
  end
end
