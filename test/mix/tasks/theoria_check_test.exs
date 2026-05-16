defmodule Mix.Tasks.Theoria.CheckTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Mix.Tasks.Theoria.Check

  test "checks built-in theorem modules" do
    Mix.Task.clear()

    output =
      capture_io(fn ->
        Check.run([])
      end)

    assert output =~ "Checking Theoria theorem modules"
    assert output =~ "Theoria.Library.Logic.Theorems"
    assert output =~ "Theoria.Library.Bool.Theorems"
    assert output =~ "Theoria.Library.Nat.Theorems"
    assert output =~ "Theoria.Library.List.Theorems"
    assert output =~ "Checked 22 theorem(s)."
  end
end
