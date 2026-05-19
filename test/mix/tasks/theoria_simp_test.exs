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

  test "prints JSON for examples" do
    Mix.Task.clear()

    output =
      capture_io(fn ->
        Simp.run(["nat_add_zero", "--prove", "--json"])
      end)

    assert output =~ "\"examples\""
    assert output =~ "\"name\":\"nat_add_zero\""
    assert output =~ "\"proof_checked\":true"
  end

  test "runs examples with checked simp artifacts" do
    Mix.Task.clear()

    output =
      capture_io(fn ->
        Simp.run(["--examples", "--prove"])
      end)

    assert output =~ "proof: checked simp.normalize"
  end

  test "does not create atoms for unknown example names" do
    Mix.Task.clear()
    unknown = "unknown_simp_example_#{System.unique_integer([:positive])}"

    assert_raise Mix.Error, ~r/unknown simplification example/, fn ->
      capture_io(fn -> Simp.run([unknown]) end)
    end

    assert_raise ArgumentError, fn -> String.to_existing_atom(unknown) end
  end
end
