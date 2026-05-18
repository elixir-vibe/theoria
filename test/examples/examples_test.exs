defmodule Theoria.ExamplesTest do
  use ExUnit.Case, async: false

  test "simp realization example runs" do
    assert {output, 0} =
             System.cmd("mix", ["run", "examples/simp_realization/run.exs"],
               stderr_to_stdout: true
             )

    assert output =~ "realized #Theoria.EquationIdentity<simp.normalize>"
    assert output =~ "installed nat_add_zero_simp_example"
  end

  test "generated equations example runs" do
    assert {output, 0} =
             System.cmd("mix", ["run", "examples/generated_equations/run.exs"],
               stderr_to_stdout: true
             )

    assert output =~ "nat_add equations:"
    assert output =~ "realized #Theoria.EquationIdentity<nat_add.eq_succ>"
  end
end
