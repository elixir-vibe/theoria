defmodule Theoria.DownstreamSmokeTest do
  use ExUnit.Case, async: false

  @fixture Path.expand("../../fixtures/downstream_project", __DIR__)

  @tag :tmp_dir
  test "downstream project compiles, checks theorem modules, and builds docs", %{tmp_dir: tmp_dir} do
    project_dir = Path.join(tmp_dir, "downstream_project")
    File.cp_r!(@fixture, project_dir)

    run_mix!(project_dir, ["deps.get"])
    run_mix!(project_dir, ["compile", "--warnings-as-errors"])

    assert_mix_fails!(
      project_dir,
      ["theoria.theorems", "DownstreamProofs"],
      "unknown constant: identity"
    )

    run_mix!(project_dir, ["theoria.theorems", "--install", "DownstreamProofs"])

    run_mix!(project_dir, [
      "theoria.kernel.check",
      "--generated-size",
      "1",
      "--generated-max-terms",
      "4",
      "--environment-depth",
      "1"
    ])

    run_mix!(project_dir, ["theoria.kernel.check", "--assurance-summary", "--json"])
    run_mix!(project_dir, ["docs"])
  end

  defp run_mix!(project_dir, args) do
    {output, status} = run_mix(project_dir, args)

    assert status == 0, "mix #{Enum.join(args, " ")} failed:\n#{output}"
    output
  end

  defp assert_mix_fails!(project_dir, args, expected_output) do
    {output, status} = run_mix(project_dir, args)

    assert status != 0, "mix #{Enum.join(args, " ")} unexpectedly passed:\n#{output}"
    assert output =~ expected_output
  end

  defp run_mix(project_dir, args) do
    root = Path.expand("../..", __DIR__)

    System.cmd("mix", args,
      cd: project_dir,
      env: [{"THEORIA_PATH", root}],
      stderr_to_stdout: true
    )
  end
end
