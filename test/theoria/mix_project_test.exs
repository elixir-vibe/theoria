defmodule Theoria.MixProjectTest do
  use ExUnit.Case, async: true

  test "ci uses native validation" do
    aliases = Theoria.MixProject.project() |> Keyword.fetch!(:aliases)
    ci = Keyword.fetch!(aliases, :ci)

    assert "theoria.validate" in ci
    refute "theoria.check" in ci
  end
end
