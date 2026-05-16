defmodule Theoria.Library.List.InductiveSpecTest do
  use ExUnit.Case, async: true

  alias Theoria.Inductive
  alias Theoria.Library.List

  test "built-in List inductive spec validates" do
    assert Inductive.validate(List.inductive_spec()) == :ok
  end

  test "List environment matches its inductive spec" do
    {:ok, env} = List.env()

    assert Inductive.verify_env(env, List.inductive_spec()) == :ok
  end
end
