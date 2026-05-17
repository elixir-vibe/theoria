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

  defmodule DependentProofs do
    use Theoria.DSL

    theorem :truth do
      type do
        term do
          true_prop()
        end
      end

      proof do
        term do
          const(:true_intro)
        end
      end
    end

    theorem :truth_again do
      type do
        term do
          true_prop()
        end
      end

      proof do
        term do
          const(:truth)
        end
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
    assert output =~ "Theoria.Library.Vec.Theorems"
    assert output =~ "Checked 45 theorem(s)."
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

  test "installs theorem modules when requested" do
    Mix.Task.clear()

    output =
      capture_io(fn ->
        Check.run(["--install", "Mix.Tasks.Theoria.CheckTest.DependentProofs"])
      end)

    assert output =~ "Mix.Tasks.Theoria.CheckTest.DependentProofs"
    assert output =~ "2 theorem(s), installed"
    assert output =~ "Checked 2 theorem(s)."
  end

  test "reports axiom summaries" do
    Mix.Task.clear()

    output =
      capture_io(fn ->
        Check.run(["--axioms"])
      end)

    assert output =~ "axioms: none"
    assert output =~ "Checked 45 theorem(s)."
  end

  test "reports axiom summaries in install mode" do
    Mix.Task.clear()

    output =
      capture_io(fn ->
        Check.run(["--install", "--axioms"])
      end)

    assert output =~ "installed, axioms: none"
    assert output =~ "Checked 45 theorem(s)."
  end

  test "dependent theorem modules fail without installation" do
    Mix.Task.clear()

    assert_raise Mix.Error, ~r/unknown constant: truth/, fn ->
      capture_io(fn ->
        Check.run(["Mix.Tasks.Theoria.CheckTest.DependentProofs"])
      end)
    end
  end

  test "raises for invalid options" do
    Mix.Task.clear()

    assert_raise Mix.Error, ~r/invalid option\(s\): --bad/, fn ->
      capture_io(fn ->
        Check.run(["--bad"])
      end)
    end
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
