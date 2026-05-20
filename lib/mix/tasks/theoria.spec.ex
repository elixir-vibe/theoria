defmodule Mix.Tasks.Theoria.Spec do
  @moduledoc """
  Runs built-in structural spec claim examples.
  """

  use Mix.Task

  alias Theoria.Spec
  alias Theoria.Spec.Claim
  alias Theoria.Spec.Examples
  alias Theoria.Spec.Report

  @shortdoc "Runs structural spec claim examples"

  @impl true
  def run(args) do
    Mix.Task.run("app.start")

    case parse_args(args) do
      {:ok, opts} ->
        claims = Examples.claims()
        report = Spec.report(claims)
        print_report(report, opts)

      {:error, message} ->
        Mix.raise(message)
    end
  end

  defp parse_args(args) do
    case OptionParser.parse(args, strict: [json: :boolean]) do
      {opts, [], []} -> {:ok, opts}
      {_opts, _argv, invalid} -> {:error, "invalid option(s): #{format_invalid_options(invalid)}"}
    end
  end

  defp format_invalid_options(invalid) do
    Enum.map_join(invalid, ", ", fn {option, _value} -> option end)
  end

  defp print_report(report, opts) do
    if Keyword.get(opts, :json, false) do
      Mix.shell().info(Jason.encode!(report))
    else
      Mix.shell().info("spec claims")
      Mix.shell().info("  total: #{Report.total(report)}")
      Mix.shell().info("  valid: #{Report.valid(report)}")
      Mix.shell().info("  invalid: #{Report.invalid(report)}")
      Mix.shell().info("  kinds: #{inspect(Report.kinds(report))}")

      Enum.each(Report.claims(report), fn claim ->
        Mix.shell().info(
          "  #{Claim.kind(claim)} valid=#{Claim.valid?(claim)} reason=#{inspect(Claim.reason(claim))}"
        )
      end)
    end
  end
end
