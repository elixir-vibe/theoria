defmodule Mix.Tasks.Theoria.TheoremsTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Mix.Tasks.Theoria.Theorems

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

    output = capture_io(fn -> Theorems.run([]) end)

    assert output =~ "Checking Theoria theorem modules"
    assert output =~ "Theoria.Library.Logic.Theorems"
    assert output =~ "Theoria.Library.Vec.Theorems"
    assert output =~ "Checked 51 theorem(s)."
  end

  test "checks explicit theorem modules" do
    Mix.Task.clear()

    output = capture_io(fn -> Theorems.run(["Mix.Tasks.Theoria.TheoremsTest.SampleProofs"]) end)

    assert output =~ "Mix.Tasks.Theoria.TheoremsTest.SampleProofs"
    assert output =~ "Checked 1 theorem(s)."
  end

  test "installs theorem modules when requested" do
    Mix.Task.clear()

    output =
      capture_io(fn ->
        Theorems.run(["--install", "Mix.Tasks.Theoria.TheoremsTest.DependentProofs"])
      end)

    assert output =~ "Mix.Tasks.Theoria.TheoremsTest.DependentProofs"
    assert output =~ "2 theorem(s), installed"
    assert output =~ "Checked 2 theorem(s)."
  end

  test "reports axiom summaries" do
    Mix.Task.clear()

    output = capture_io(fn -> Theorems.run(["--axioms"]) end)

    assert output =~ "axioms: none"
    assert output =~ "Checked 51 theorem(s)."
  end

  test "dependent theorem modules fail without installation" do
    Mix.Task.clear()

    assert_raise Mix.Error, ~r/unknown constant: truth/, fn ->
      capture_io(fn -> Theorems.run(["Mix.Tasks.Theoria.TheoremsTest.DependentProofs"]) end)
    end
  end

  test "raises for invalid options" do
    Mix.Task.clear()

    assert_raise Mix.Error, ~r/invalid option\(s\): --bad/, fn ->
      capture_io(fn -> Theorems.run(["--bad"]) end)
    end
  end
end
