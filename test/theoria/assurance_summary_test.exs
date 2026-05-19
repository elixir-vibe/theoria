defmodule Theoria.AssuranceSummaryTest do
  use ExUnit.Case, async: true

  alias Theoria.Kernel.AssuranceSummary
  alias Theoria.Kernel.Differential
  alias Theoria.Kernel.Differential.Options
  alias Theoria.Prelude

  test "accessors expose summary sections" do
    {:ok, env} = Prelude.env()
    {:ok, opts} = Options.parse(generated_size: 1, generated_max_terms: 4, environment_depth: 1)

    summary =
      env
      |> Differential.run(opts)
      |> AssuranceSummary.from_report()

    assert AssuranceSummary.curated(summary).infer > 0
    assert AssuranceSummary.generated_terms(summary).total > 0
    assert AssuranceSummary.environments(summary).cases == 4
    assert AssuranceSummary.artifacts(summary).generated > 0
    assert AssuranceSummary.theorem_count(summary) > 0
    assert AssuranceSummary.replay_count(summary) > 0
  end
end
