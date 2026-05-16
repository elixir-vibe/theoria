defmodule Theoria.Library.Nat.InductiveSpecTest do
  use ExUnit.Case, async: true

  alias Theoria.Inductive
  alias Theoria.Library.Nat

  test "built-in Nat inductive spec validates" do
    assert Inductive.validate(Nat.inductive_spec()) == :ok
  end
end
