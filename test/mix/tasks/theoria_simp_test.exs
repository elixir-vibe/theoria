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

  test "explains proof capabilities" do
    Mix.Task.clear()

    output =
      capture_io(fn ->
        Simp.run(["nat_add_zero", "--prove", "--explain"])
      end)

    assert output =~ "explain path="
    assert output =~ "capability="
  end

  test "prints proof capabilities without running examples" do
    Mix.Task.clear()

    output =
      capture_io(fn ->
        Simp.run(["--capabilities"])
      end)

    assert output =~ "proof capabilities:"
    assert output =~ "application_congruence"
  end

  test "prints JSON proof capabilities" do
    Mix.Task.clear()

    output =
      capture_io(fn ->
        Simp.run(["--capabilities", "--json"])
      end)

    assert output =~ "\"proof_capabilities\""
    assert output =~ "\"path\""
    assert output =~ "\"capability\""
    assert output =~ "\"supported\""
    assert output =~ "\"reason\""
    assert output =~ "\"description\""
    assert output =~ "\"inner\""
    assert output =~ "eq_rec_base_congruence"
  end

  test "prints JSON for examples" do
    Mix.Task.clear()

    output =
      capture_io(fn ->
        Simp.run(["nat_add_zero", "--prove", "--json"])
      end)

    assert {:ok, json} = Jason.decode(output)
    assert [%{"name" => "nat_add_zero", "proof_checked" => true}] = json["examples"]

    assert output =~ "\"examples\""
    assert output =~ "\"proof\""
    assert output =~ "\"proof_status\""
    assert output =~ "\"proof_capability\""
    assert output =~ "\"has_proof\""
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
