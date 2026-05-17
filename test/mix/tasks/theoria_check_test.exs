defmodule Mix.Tasks.Theoria.CheckTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Mix.Tasks.Theoria.Check

  test "checks the native validation corpus" do
    Mix.Task.clear()

    output =
      capture_io(fn ->
        Check.run([])
      end)

    assert output =~ "Validating Theoria corpus"
    assert output =~ "✓ theorem modules: 53 theorem(s)"
    assert output =~ "✓ defeq checks: 57 check(s)"
    assert output =~ "✓ inductive specs: 4 check(s)"
    assert output =~ "✓ equation metadata: 6 definition(s)"
    assert output =~ "✓ matcher declarations: 6 checked matcher(s)"
    assert output =~ "✓ generated equations: 16 theorem(s)"
    assert output =~ "✓ matcher equations: 16 theorem(s)"
  end

  test "passes options through to validation" do
    Mix.Task.clear()

    output =
      capture_io(fn ->
        Check.run(["--only", "logic", "--axioms"])
      end)

    assert output =~ "✓ theorem modules: 12 theorem(s), axioms: none"
    assert output =~ "✓ defeq checks: 0 check(s)"
    assert output =~ "✓ inductive specs: 0 check(s)"
    assert output =~ "✓ equation metadata: 6 definition(s)"
    assert output =~ "✓ matcher declarations: 6 checked matcher(s)"
    assert output =~ "✓ generated equations: 16 theorem(s)"
    assert output =~ "✓ matcher equations: 16 theorem(s)"
  end
end
