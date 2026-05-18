defmodule Theoria.Equation.Matcher.Statement.FrameTest do
  use ExUnit.Case, async: true

  alias Theoria.Equation.Matcher.Statement.Frame
  alias Theoria.Term

  test "ref resolves de Bruijn indices from the newest binder" do
    frame = Frame.new(a: Term.const(:A), b: Term.const(:B), c: Term.const(:C))

    assert Frame.ref(frame, :c) == {:ok, Term.bvar(0)}
    assert Frame.ref(frame, :b) == {:ok, Term.bvar(1)}
    assert Frame.ref(frame, :a) == {:ok, Term.bvar(2)}
  end

  test "shadowed names resolve to the newest binder" do
    frame = Frame.new(a: Term.const(:A)) |> Frame.push(:a, Term.const(:B))

    assert Frame.ref(frame, :a) == {:ok, Term.bvar(0)}
    assert Frame.binders(frame) == [a: Term.const(:A), a: Term.const(:B)]
  end

  test "push adjusts existing refs" do
    frame = Frame.new(a: Term.const(:A))
    pushed = Frame.push(frame, :b, Term.const(:B))

    assert Frame.ref(frame, :a) == {:ok, Term.bvar(0)}
    assert Frame.ref(pushed, :a) == {:ok, Term.bvar(1)}
    assert Frame.ref(pushed, :b) == {:ok, Term.bvar(0)}
  end

  test "forall preserves binder order" do
    frame = Frame.new(a: Term.const(:A), b: Term.const(:B))

    assert Frame.forall(frame, Term.const(:Body)) ==
             Term.forall(:a, Term.const(:A), Term.forall(:b, Term.const(:B), Term.const(:Body)))
  end

  test "missing binders return tagged errors" do
    assert Frame.ref(Frame.new([]), :missing) ==
             {:error, {:unknown_indexed_matcher_statement_binder, :missing}}
  end
end
