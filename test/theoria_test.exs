defmodule TheoriaTest do
  use ExUnit.Case, async: true

  doctest Theoria
  doctest Theoria.Equation.Identity
  doctest Theoria.Equation.Summary

  test "creates an empty environment" do
    assert %Theoria.Env{} = Theoria.new_env()
  end
end
