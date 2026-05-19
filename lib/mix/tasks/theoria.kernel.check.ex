defmodule Mix.Tasks.Theoria.Kernel.Check do
  @moduledoc "Runs production/reference kernel differential checks."

  use Mix.Task

  alias Theoria.Kernel.Coverage
  alias Theoria.Kernel.Differential
  alias Theoria.Prelude

  @shortdoc "Runs kernel differential checks"

  @impl true
  def run(args) do
    Mix.Task.run("app.start")

    with {opts, [], []} <-
           OptionParser.parse(args,
             strict: [coverage: :boolean, json: :boolean, verbose: :boolean]
           ),
         {:ok, env} <- Prelude.env() do
      report = Differential.run(env)
      print_report(env, report, opts)
      maybe_raise(report)
    else
      {_opts, _args, invalid} ->
        Mix.raise("invalid option(s): #{format_invalid_options(invalid)}")

      {:error, reason} ->
        Mix.raise("failed to build Theoria prelude: #{inspect(reason)}")
    end
  end

  defp print_report(env, report, opts) do
    if Keyword.get(opts, :json, false) do
      output =
        if Keyword.get(opts, :coverage, false) do
          %{
            report: report,
            coverage: Coverage.summary(env, report),
            artifact_replay: report.artifact_replay
          }
        else
          report
        end

      Mix.shell().info(Jason.encode!(output))
    else
      Mix.shell().info("Kernel differential checks...")
      Mix.shell().info("✓ infer checks: #{report.infer_count}")
      Mix.shell().info("✓ check checks: #{report.check_count}")
      Mix.shell().info("✓ normalize checks: #{report.normalize_count}")
      Mix.shell().info("✓ defeq checks: #{report.defeq_count}")
      Mix.shell().info("✓ rejection checks: #{report.rejection_count}")
      Mix.shell().info("✓ theorem checks: #{report.theorem_count}")
      Mix.shell().info("✓ theorem replay checks: #{report.theorem_replay_count}")
      Mix.shell().info("- theorem replay skipped: #{report.theorem_replay_skipped}")
      Mix.shell().info("✓ generated artifact checks: #{report.generated_artifact_count}")
      Mix.shell().info("✓ indexed artifact checks: #{report.indexed_artifact_count}")
      Mix.shell().info("✓ replay checks: #{report.replay_count}")
      Mix.shell().info("- replay skipped: #{report.replay_skipped}")
      Mix.shell().info("✓ artifact replay checks: #{report.artifact_replay_count}")

      Mix.shell().info(
        "  generated artifact replay checks: #{report.generated_artifact_replay_count}"
      )

      Mix.shell().info(
        "  indexed artifact replay checks: #{report.indexed_artifact_replay_count}"
      )

      Mix.shell().info("- artifact replay skipped: #{report.artifact_replay_skipped}")
      maybe_print_verbose(report, opts)
      maybe_print_coverage(env, report, opts)
    end
  end

  defp maybe_print_verbose(report, opts) do
    if Keyword.get(opts, :verbose, false) do
      Mix.shell().info("")
      Mix.shell().info("verbose:")
      Mix.shell().info("  corpus: infer=#{report.infer_count} check=#{report.check_count}")
      Mix.shell().info("  normalize=#{report.normalize_count} defeq=#{report.defeq_count}")
      Mix.shell().info("  rejected=#{report.rejection_count}")
      Mix.shell().info("  modules=#{report.theorem_count}")

      Enum.each(report.theorem_modules, fn module ->
        Mix.shell().info("    #{module.module}: #{module.checks}")
      end)

      Mix.shell().info(
        "  theorem_replay=#{report.theorem_replay_count} skipped=#{report.theorem_replay_skipped}"
      )

      Mix.shell().info("  generated_artifacts=#{report.generated_artifact_count}")
      Mix.shell().info("  indexed_artifacts=#{report.indexed_artifact_count}")
      Mix.shell().info("  replay=#{report.replay_count} skipped=#{report.replay_skipped}")

      Mix.shell().info(
        "  artifact_replay=#{report.artifact_replay_count} generated=#{report.generated_artifact_replay_count} indexed=#{report.indexed_artifact_replay_count} skipped=#{report.artifact_replay_skipped}"
      )

      print_artifact_replay_skips(report.artifact_replay_skips)

      Mix.shell().info("  failures=#{length(report.failures)}")
    end
  end

  defp print_artifact_replay_skips([]), do: :ok

  defp print_artifact_replay_skips(skips) do
    Mix.shell().info("  artifact replay skipped:")

    Enum.each(skips, fn skip ->
      Mix.shell().info("    - #{inspect(skip.name)}: #{skip.reason} #{inspect(skip.details)}")
    end)
  end

  defp maybe_print_coverage(env, report, opts) do
    if Keyword.get(opts, :coverage, false) do
      coverage = Coverage.summary(env, report)

      Mix.shell().info("")
      Mix.shell().info("coverage:")
      Mix.shell().info("  supported_terms=#{length(coverage.supported_term_constructors)}")
      Mix.shell().info("  unsupported_terms=#{length(coverage.unsupported_term_constructors)}")
      Mix.shell().info("  declaration_kinds=#{inspect(coverage.declaration_kinds)}")
      Mix.shell().info("  theorem_modules=#{coverage.theorem_module_checks}")
      Mix.shell().info("  generated_artifacts=#{coverage.generated_artifact_checks}")
      Mix.shell().info("  indexed_artifacts=#{coverage.indexed_artifact_checks}")
      Mix.shell().info("  replay=#{coverage.replay_checks} skipped=#{coverage.replay_skipped}")

      Mix.shell().info(
        "  artifact_replay=#{coverage.artifact_replay_checks} generated=#{coverage.generated_artifact_replay_checks} indexed=#{coverage.indexed_artifact_replay_checks} skipped=#{coverage.artifact_replay_skipped}"
      )

      Mix.shell().info("  property_families=#{Enum.join(coverage.property_families, ", ")}")
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
