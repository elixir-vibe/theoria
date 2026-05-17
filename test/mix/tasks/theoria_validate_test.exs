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
    assert output =~ "✓ defeq checks: 57 check(s)"
    assert output =~ "✓ inductive specs: 4 check(s)"
    assert output =~ "✓ equation metadata: 6 definition(s)"
    assert output =~ "✓ matcher declarations: 6 checked matcher(s)"
    assert output =~ "✓ generated equations: 16 theorem(s)"
    assert output =~ "✓ matcher equations: 16 theorem(s)"
  end

  test "reports axioms when requested" do
    Mix.Task.clear()

    output =
      capture_io(fn ->
        Validate.run(["--axioms"])
      end)

    assert output =~ "✓ theorem modules: 53 theorem(s), axioms: none"
  end

  test "reports equation metadata when requested" do
    Mix.Task.clear()

    output =
      capture_io(fn ->
        Validate.run(["--equations"])
      end)

    assert output =~ "equations:"
    assert output =~ "bool_not rec_arg=0 fixed=[]"
    assert output =~ "nat_add rec_arg=0 fixed=[]"
    assert output =~ "list_append rec_arg=1 fixed=[0] levels=[:u]"
  end

  test "reports generated equation lemmas when requested" do
    Mix.Task.clear()

    output =
      capture_io(fn ->
        Validate.run(["--equations", "--verbose"])
      end)

    assert output =~ "bool_not.eq_true"
    assert output =~ "nat_add.eq_succ"
    assert output =~ "list_append.eq_nil"
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
    assert output =~ "✓ equation metadata: 6 definition(s)"
    assert output =~ "✓ matcher declarations: 6 checked matcher(s)"
    assert output =~ "✓ generated equations: 16 theorem(s)"
    assert output =~ "✓ matcher equations: 16 theorem(s)"
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
