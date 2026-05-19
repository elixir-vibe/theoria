defmodule Mix.Tasks.Theoria.Kernel.Check do
  @moduledoc "Runs production/reference kernel differential checks."

  use Mix.Task

  alias Theoria.Kernel.Differential
  alias Theoria.Prelude

  @shortdoc "Runs kernel differential checks"

  @impl true
  def run(args) do
    Mix.Task.run("app.start")

    with {opts, [], []} <- OptionParser.parse(args, strict: [json: :boolean]),
         {:ok, env} <- Prelude.env() do
      report = Differential.run(env)
      print_report(report, opts)
      maybe_raise(report)
    else
      {_opts, _args, invalid} ->
        Mix.raise("invalid option(s): #{format_invalid_options(invalid)}")

      {:error, reason} ->
        Mix.raise("failed to build Theoria prelude: #{inspect(reason)}")
    end
  end

  defp print_report(report, opts) do
    if Keyword.get(opts, :json, false) do
      Mix.shell().info(Jason.encode!(report))
    else
      Mix.shell().info("Kernel differential checks...")
      Mix.shell().info("✓ infer checks: #{report.infer_count}")
      Mix.shell().info("✓ check checks: #{report.check_count}")
      Mix.shell().info("✓ normalize checks: #{report.normalize_count}")
      Mix.shell().info("✓ defeq checks: #{report.defeq_count}")
    end
  end

  defp maybe_raise(report) do
    unless Differential.Report.ok?(report) do
      Mix.raise("kernel differential failures: #{inspect(report.failures)}")
    end
  end

  defp format_invalid_options(invalid) do
    Enum.map_join(invalid, ", ", fn {option, _value} -> option end)
  end
end
