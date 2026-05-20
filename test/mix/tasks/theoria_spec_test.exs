defmodule Mix.Tasks.Theoria.SpecTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Mix.Tasks.Theoria.Spec

  test "prints built-in spec claim examples" do
    Mix.Task.clear()

    output = capture_io(fn -> Spec.run([]) end)

    assert output =~ "spec claims"
    assert output =~ "total: 5"
    assert output =~ "valid: 4"
    assert output =~ "invalid: 1"
    assert output =~ "graph_path valid=true"
    assert output =~ "effect_delta valid=false"
  end

  test "prints JSON report" do
    Mix.Task.clear()

    output = capture_io(fn -> Spec.run(["--json"]) end)

    assert {:ok, json} = Jason.decode(output)
    assert json["total"] == 5
    assert json["valid"] == 4
    assert json["invalid"] == 1
    assert is_list(json["claims"])
  end

  test "raises for invalid options" do
    Mix.Task.clear()

    assert_raise Mix.Error, ~r/invalid option\(s\): --bad/, fn ->
      capture_io(fn -> Spec.run(["--bad"]) end)
    end
  end
end
