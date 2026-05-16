defmodule Theoria.Library.Bool.InductiveSpecTest do
  use ExUnit.Case, async: true

  alias Theoria.Inductive
  alias Theoria.Library.Bool

  test "built-in Bool inductive spec validates" do
    assert Inductive.validate(Bool.inductive_spec()) == :ok
  end
end
