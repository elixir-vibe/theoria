defmodule TheoriaTest do
  use ExUnit.Case, async: true

  doctest Theoria

  test "creates an empty environment" do
    assert %Theoria.Env{} = Theoria.new_env()
  end
end
