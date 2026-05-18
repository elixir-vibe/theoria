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

  test "lists built-in examples" do
    Mix.Task.clear()

    output =
      capture_io(fn ->
        Simp.run(["--list"])
      end)

    assert output =~ "bool_not_true"
    assert output =~ "nat_add_zero"
  end

  test "runs a selected example" do
    Mix.Task.clear()

    output =
      capture_io(fn ->
        Simp.run(["nat_add_zero", "--prove"])
      end)

    assert output =~ "nat_add_zero"
    refute output =~ "bool_not_true"
    assert output =~ "proof: checked simp.normalize"
  end

  test "runs examples with checked simp artifacts" do
    Mix.Task.clear()

    output =
      capture_io(fn ->
        Simp.run(["--examples", "--prove"])
      end)

    assert output =~ "proof: checked simp.normalize"
  end
end
