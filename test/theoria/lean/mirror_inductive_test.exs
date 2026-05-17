defmodule Theoria.Lean.MirrorInductiveTest do
  use ExUnit.Case, async: true

  alias Theoria.Lean.Mirror.Inductive
  alias Theoria.Library.{Bool, Vec}

  test "reports supported inductive specs conservatively" do
    assert Inductive.supports?(Vec.inductive_spec())
    refute Inductive.supports?(Bool.inductive_spec())
    assert Inductive.unsupported_reason(Bool.inductive_spec()) =~ "Vec-like"
  end

  test "generates Vec inductive source from the Theoria spec" do
    source = Inductive.source!(Vec.inductive_spec())
    snippet = File.read!("test/support/lean_oracle_snippets/vec_inductive.lean")

    assert source =~ snippet
    assert source =~ "inductive TVec"
    assert source =~ "| vec_nil"
    assert source =~ "| vec_cons"
    refute source =~ "Vector"
  end
end
