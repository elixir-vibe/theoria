defmodule Mix.Tasks.Theoria.TypespecsTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Mix.Tasks.Theoria.Typespecs

  test "lists normalized typespec contracts" do
    Mix.Task.clear()

    output = capture_io(fn -> Typespecs.run(["Theoria.Obligation"]) end)

    assert output =~ "Theoria.Obligation:"
    assert output =~ "Theoria.Obligation.new(atom()"
    assert output =~ "contract(s)"
  end

  test "prints JSON reports" do
    Mix.Task.clear()

    output = capture_io(fn -> Typespecs.run(["--json", "Theoria.Certificate.Report"]) end)

    assert {:ok, json} = Jason.decode(output)
    assert [report] = json["reports"]
    assert report["module"] == "Theoria.Certificate.Report"
    assert report["total"] > 0
    assert is_list(report["contracts"])
  end

  test "raises for invalid options" do
    Mix.Task.clear()

    assert_raise Mix.Error, ~r/invalid option\(s\): --bad/, fn ->
      capture_io(fn -> Typespecs.run(["--bad", "Theoria.Obligation"]) end)
    end
  end

  test "does not create atoms for unknown module names" do
    Mix.Task.clear()
    unknown = "Unknown.Typespec.Module.#{System.unique_integer([:positive])}"

    assert_raise Mix.Error, ~r/unknown module/, fn ->
      capture_io(fn -> Typespecs.run([unknown]) end)
    end

    assert_raise ArgumentError, fn -> String.to_existing_atom("Elixir." <> unknown) end
  end
end
