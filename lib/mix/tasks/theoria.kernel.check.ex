defmodule Mix.Tasks.Theoria.Kernel.Check do
  @moduledoc "Runs production/reference kernel differential checks."

  use Mix.Task

  alias Theoria.Kernel.Differential
  alias Theoria.Prelude

  @shortdoc "Runs kernel differential checks"

  @impl true
  def run(_args) do
    Mix.Task.run("app.start")

    case Prelude.env() do
      {:ok, env} ->
        report = Differential.run(env)
        Mix.shell().info("Kernel differential checks...")
        Mix.shell().info("✓ infer checks: #{report.infer_count}")
        Mix.shell().info("✓ check checks: #{report.check_count}")

        if Differential.Report.ok?(report) do
          :ok
        else
          Mix.raise("kernel differential failures: #{inspect(report.failures)}")
        end

      {:error, reason} ->
        Mix.raise("failed to build Theoria prelude: #{inspect(reason)}")
    end
  end
end
