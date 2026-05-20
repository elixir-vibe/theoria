defmodule TheoriaTest do
  use ExUnit.Case, async: true

  doctest Theoria
  doctest Theoria.Equation.Identity
  doctest Theoria.Equation.Report
  doctest Theoria.Equation.Summary
  doctest Theoria.Simp.ExampleReport
  doctest Theoria.Simp.Report
  doctest Theoria.Theorem.ModuleReport
  doctest Theoria.Theorem.Report

  test "creates an empty environment" do
    assert %Theoria.Env{} = Theoria.new_env()
  end
end
