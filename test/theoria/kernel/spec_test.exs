defmodule Theoria.Kernel.SpecTest do
  use ExUnit.Case, async: true

  alias Theoria.Kernel.Spec

  test "documents the first reference-checker syntax fragment" do
    assert :sort in Keyword.keys(Spec.syntax())
    assert :refl in Keyword.keys(Spec.syntax())
    assert :infer in Spec.judgments()
    assert :eq_rec in Spec.unsupported_terms()
  end
end
