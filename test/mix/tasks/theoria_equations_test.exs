defmodule Mix.Tasks.Theoria.EquationsTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Mix.Tasks.Theoria.Equations

  test "lists equation metadata and generated lemma names" do
    Mix.Task.clear()

    output =
      capture_io(fn ->
        Equations.run([])
      end)

    assert output =~ "equations:"
    assert output =~ "bool_not rec_arg=0 fixed=[]"
    assert output =~ "bool_not.eq_true"
    assert output =~ "list_append rec_arg=1 fixed=[0] levels=[:u]"
    assert output =~ "list_append.eq_nil"
  end

  test "filters equations by definition name" do
    Mix.Task.clear()

    output =
      capture_io(fn ->
        Equations.run(["nat_add"])
      end)

    assert output =~ "nat_add rec_arg=0 fixed=[]"
    assert output =~ "nat_add.eq_succ"
    refute output =~ "bool_not rec_arg=0 fixed=[]"
  end

  test "installs generated equations on request" do
    Mix.Task.clear()

    output =
      capture_io(fn ->
        Equations.run(["--install", "nat_add"])
      end)

    assert output =~ "nat_add.eq_succ"
    assert output =~ "Installed 2 equation theorem(s)."
  end
end
