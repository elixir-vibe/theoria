defmodule Mix.Tasks.Theoria.Typespecs do
  @moduledoc """
  Lists normalized Elixir typespec contracts for loaded modules.
  """

  use Mix.Task

  alias Theoria.Typespec
  alias Theoria.Typespec.Contract
  alias Theoria.Typespec.Report

  @shortdoc "Lists normalized Elixir typespec contracts"

  @impl true
  def run(args) do
    Mix.Task.run("app.start")

    with {:ok, opts, module_args} <- parse_args(args),
         {:ok, modules} <- modules(module_args) do
      reports = Enum.map(modules, &typespec_report!/1)
      print_reports(reports, opts)
    else
      {:error, message} when is_binary(message) -> Mix.raise(message)
    end
  end

  defp parse_args(args) do
    case OptionParser.parse(args, strict: [json: :boolean]) do
      {opts, module_args, []} ->
        {:ok, opts, module_args}

      {_opts, _module_args, invalid} ->
        {:error, "invalid option(s): #{format_invalid_options(invalid)}"}
    end
  end

  defp format_invalid_options(invalid) do
    Enum.map_join(invalid, ", ", fn {option, _value} -> option end)
  end

  defp modules([]), do: {:error, "expected at least one module name"}

  defp modules(args) do
    args
    |> Enum.reduce_while({:ok, []}, fn name, {:ok, modules} ->
      case module_from_name(name) do
        {:ok, module} -> {:cont, {:ok, [module | modules]}}
        :error -> {:halt, {:error, "unknown module #{name}"}}
      end
    end)
    |> then(fn
      {:ok, modules} -> {:ok, Enum.reverse(modules)}
      {:error, message} -> {:error, message}
    end)
  end

  defp module_from_name("Elixir." <> _ = name), do: existing_module(name)
  defp module_from_name(name), do: existing_module("Elixir." <> name)

  defp existing_module(name) do
    module = String.to_existing_atom(name)

    if Code.ensure_loaded?(module), do: {:ok, module}, else: :error
  rescue
    ArgumentError -> :error
  end

  defp typespec_report!(module) do
    case Typespec.report(module) do
      {:ok, report} ->
        report

      {:error, :no_typespecs} ->
        Mix.raise("no typespec metadata found for #{inspect(module)}")
    end
  end

  defp print_reports(reports, opts) do
    if Keyword.get(opts, :json, false) do
      Mix.shell().info(Jason.encode!(%{reports: reports}))
    else
      Enum.each(reports, &print_report/1)
    end
  end

  defp print_report(%Report{} = report) do
    Mix.shell().info(
      "#{inspect(report.module)}: #{Report.total(report)} contract(s), unsupported=#{Report.unsupported(report)}"
    )

    Enum.each(Report.contracts(report), fn contract ->
      unsupported = if Contract.unsupported?(contract), do: " unsupported=true", else: ""
      Mix.shell().info("  #{Contract.format(contract)}#{unsupported}")
    end)
  end
end
