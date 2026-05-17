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

    assert output =~ "matcher declarations: 6"
    assert output =~ "registry entries: 38"
    assert output =~ "equations:"
    assert output =~ "bool_not rec_arg=0 fixed=[]"
    assert output =~ "bool_not.eq_true"
    assert output =~ "matcher: bool_not.match_1"
    assert output =~ "discriminants:"
    assert output =~ "alternatives:"
    assert output =~ "unfold: bool_not.eq_def"
    assert output =~ "list_append rec_arg=1 fixed=[0] levels=[:u]"
    assert output =~ "matcher: list_append.match_1 mode=matcher arity=5"
    assert output =~ "list_append.eq_nil"
    assert output =~ "list_append.match_1.eq_list_cons"
  end

  test "filters equations by definition name" do
    Mix.Task.clear()

    output =
      capture_io(fn ->
        Equations.run(["nat_add"])
      end)

    assert output =~ "nat_add rec_arg=0 fixed=[]"
    assert output =~ "matcher: nat_add.match_1 mode=matcher arity=4"
    assert output =~ "0: m position=0 family=nat"
    assert output =~ "nat_add.eq_succ"
    assert output =~ "nat_add.match_1.eq_succ"
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
