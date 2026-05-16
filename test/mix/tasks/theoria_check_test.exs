defmodule Mix.Tasks.Theoria.CheckTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Mix.Tasks.Theoria.Check

  defmodule SampleProofs do
    use Theoria.DSL

    theorem :true_is_true do
      type do
        const(:True)
      end

      proof do
        const(:true_intro)
      end
    end
  end

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
    assert output =~ "Checked 41 theorem(s)."
  end

  test "checks explicit theorem modules" do
    Mix.Task.clear()

    output =
      capture_io(fn ->
        Check.run(["Mix.Tasks.Theoria.CheckTest.SampleProofs"])
      end)

    assert output =~ "Mix.Tasks.Theoria.CheckTest.SampleProofs"
    assert output =~ "Checked 1 theorem(s)."
  end

  test "raises for modules that cannot be loaded" do
    Mix.Task.clear()

    assert_raise Mix.Error, ~r/could not load theorem module Does.Not.Exist/, fn ->
      capture_io(fn ->
        Check.run(["Does.Not.Exist"])
      end)
    end
  end

  test "raises for modules without theorem registry" do
    Mix.Task.clear()

    assert_raise Mix.Error, ~r/String is not a Theoria theorem module/, fn ->
      capture_io(fn ->
        Check.run(["String"])
      end)
    end
  end
end
