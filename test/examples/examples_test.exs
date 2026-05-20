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
    assert {output, 0} = run_example("examples/generated_equations/run.exs")

    assert output =~ "nat_add equations:"
    assert output =~ "realized #Theoria.EquationIdentity<nat_add.eq_succ>"
  end

  test "theorem module example runs" do
    assert {output, 0} = run_example("examples/theorem_module/run.exs")

    assert output =~ "theorem: :identity"
    assert output =~ "registered: [:identity, :identity_again]"
    assert output =~ "installed: [:identity, :identity_again]"
  end

  test "kernel reports example runs" do
    assert {output, 0} = run_example("examples/kernel_reports/run.exs")

    assert output =~ "kernel differential"
    assert output =~ "generated terms"
  end

  test "simp capabilities example runs" do
    assert {output, 0} = run_example("examples/simp_capabilities/run.exs")

    assert output =~ "proof capabilities"
  end

  test "proof simp trace example runs" do
    assert {output, 0} = run_example("examples/proof_simp_trace/run.exs")

    assert output =~ "proof-producing rewrite trace"
  end

  defp run_example(path) do
    System.cmd("mix", ["run", path], env: [{"MIX_ENV", "dev"}], stderr_to_stdout: true)
  end
end
