defmodule Mix.Tasks.Theoria.SimpTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Mix.Tasks.Theoria.Simp

  test "runs built-in simplification examples" do
    Mix.Task.clear()

    output =
      capture_io(fn ->
        Simp.run(["--examples"])
      end)

    assert output =~ "simplification examples:"
    assert output =~ "bool_not_true"
    assert output =~ "nat_add_zero"
    assert output =~ "list_append_nil"
    assert output =~ "nat_add.eq_zero"
  end
end
