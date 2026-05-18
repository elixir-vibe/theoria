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
    assert output =~ "matcher: bool_not_match_1"
    assert output =~ "discriminants:"
    assert output =~ "alternatives:"
    assert output =~ "unfold: bool_not.eq_def"
    assert output =~ "list_append rec_arg=1 fixed=[0] levels=[:u]"
    assert output =~ "matcher: list_append_match_1 mode=matcher arity=5"
    assert output =~ "descriptor: family=list discrs=1 alts=2 recursor=list_rec"
    assert output =~ "list_append.eq_nil"
    assert output =~ "list_append_match_1.eq_list_cons"
  end

  test "filters equations by definition name" do
    Mix.Task.clear()

    output =
      capture_io(fn ->
        Equations.run(["nat_add"])
      end)

    assert output =~ "nat_add rec_arg=0 fixed=[]"
    assert output =~ "matcher: nat_add_match_1 mode=matcher arity=4"
    assert output =~ "descriptor: family=nat discrs=1 alts=2 recursor=nat_rec"
    assert output =~ "0: m position=0 family=nat"
    assert output =~ "nat_add.eq_succ"
    assert output =~ "nat_add_match_1.eq_succ"
    refute output =~ "bool_not rec_arg=0 fixed=[]"
  end

  test "prints binary Bool descriptor details" do
    Mix.Task.clear()

    output =
      capture_io(fn ->
        Equations.run(["bool_and"])
      end)

    assert output =~ "matcher: bool_and_match_1 mode=matcher arity=7"
    assert output =~ "descriptor: family=bool discrs=2 alts=4 recursor=bool_rec"
    assert output =~ "true_true fields=0"
    assert output =~ "false_false fields=0"
  end

  test "realizes generated equations on request" do
    Mix.Task.clear()

    output =
      capture_io(fn ->
        Equations.run(["--realize", "nat_add"])
      end)

    assert output =~ "nat_add.eq_succ"
    assert output =~ "Realized 2 equation artifact(s)."
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
