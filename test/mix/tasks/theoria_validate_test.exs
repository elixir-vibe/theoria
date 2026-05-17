defmodule Mix.Tasks.Theoria.ValidateTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Mix.Tasks.Theoria.Validate

  test "validates the default corpus" do
    Mix.Task.clear()

    output =
      capture_io(fn ->
        Validate.run([])
      end)

    assert output =~ "Validating Theoria corpus"
    assert output =~ "✓ theorem modules: 53 theorem(s)"
    assert output =~ "✓ defeq checks: 52 check(s)"
    assert output =~ "✓ inductive specs: 4 check(s)"
  end

  test "reports axioms when requested" do
    Mix.Task.clear()

    output =
      capture_io(fn ->
        Validate.run(["--axioms"])
      end)

    assert output =~ "✓ theorem modules: 53 theorem(s), axioms: none"
  end

  test "validates filtered corpus" do
    Mix.Task.clear()

    output =
      capture_io(fn ->
        Validate.run(["--only", "vec"])
      end)

    assert output =~ "✓ theorem modules: 4 theorem(s)"
    assert output =~ "✓ defeq checks: 4 check(s)"
    assert output =~ "✓ inductive specs: 1 check(s)"
  end

  test "parses comma-separated categories" do
    assert Validate.__parse_args__(["--only", "bool,nat"])[:only] == [:bool, :nat]
  end

  test "rejects invalid categories" do
    assert_raise Mix.Error, ~r/invalid --only value: wat/, fn ->
      Validate.__parse_args__(["--only", "wat"])
    end
  end
end
