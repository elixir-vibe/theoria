defmodule Mix.Tasks.Theoria.Theorems do
  @moduledoc """
  Checks Theoria theorem modules against the standard prelude.
  """

  use Mix.Task

  alias Theoria.Theorem
  alias Theoria.Theorem.ModuleReport
  alias Theoria.Theorem.Report
  alias Theoria.Validation.Corpus

  @shortdoc "Checks Theoria theorem modules"

  @impl true
  def run(args) do
    Mix.Task.run("app.start")

    with {:ok, opts, module_args} <- parse_args(args),
         {:ok, modules} <- theorem_modules(module_args),
         {:ok, env} <- Theoria.Prelude.env() do
      check_modules(env, modules, opts)
    else
      {:error, %Theoria.Error{} = error} ->
        Mix.raise("failed to build Theoria prelude:\n\n#{Exception.message(error)}")

      {:error, message} when is_binary(message) ->
        Mix.raise(message)
    end
  end

  defp parse_args(args) do
    case OptionParser.parse(args, strict: [install: :boolean, axioms: :boolean, json: :boolean]) do
      {opts, module_args, []} ->
        {:ok, opts, module_args}

      {_opts, _module_args, invalid} ->
        {:error, "invalid option(s): #{format_invalid_options(invalid)}"}
    end
  end

  defp format_invalid_options(invalid) do
    Enum.map_join(invalid, ", ", fn {option, _value} -> option end)
  end

  defp theorem_modules([]), do: {:ok, Corpus.builtin_theorem_modules()}

  defp theorem_modules(args) do
    available = Map.new(available_theorem_modules(), &{module_name(&1), &1})

    args
    |> Enum.reduce_while({:ok, []}, fn name, {:ok, modules} ->
      case theorem_module(name, available) do
        {:ok, module} -> {:cont, {:ok, [module | modules]}}
        :error -> {:halt, {:error, "unknown theorem module #{name}"}}
      end
    end)
    |> then(fn
      {:ok, modules} -> {:ok, Enum.reverse(modules)}
      {:error, message} -> {:error, message}
    end)
  end

  defp theorem_module(name, available) do
    case Map.fetch(available, name) do
      {:ok, module} -> {:ok, module}
      :error -> ensure_theorem_module(name)
    end
  end

  defp ensure_theorem_module(name) do
    with {:ok, module} <- module_from_name(name),
         {:module, ^module} <- Code.ensure_loaded(module),
         true <- function_exported?(module, :__theoria_theorems__, 0) do
      {:ok, module}
    else
      _other -> :error
    end
  end

  defp module_from_name(name) do
    name
    |> String.split(".", trim: true)
    |> Module.safe_concat()
    |> then(&{:ok, &1})
  rescue
    ArgumentError -> :error
  end

  defp available_theorem_modules do
    loaded_theorem_modules =
      :code.all_loaded()
      |> Enum.map(fn {module, _path} -> module end)
      |> Enum.filter(&function_exported?(&1, :__theoria_theorems__, 0))

    (Corpus.builtin_theorem_modules() ++ loaded_theorem_modules)
    |> Enum.uniq()
  end

  defp module_name(module), do: module |> Module.split() |> Enum.join(".")

  defp check_modules(env, modules, opts) do
    unless Keyword.get(opts, :json, false),
      do: Mix.shell().info("Checking Theoria theorem modules...\n")

    report =
      if Keyword.get(opts, :install, false) do
        check_modules_installed(env, modules, opts)
      else
        check_modules_plain(env, modules, opts)
      end

    if Keyword.get(opts, :json, false) do
      Mix.shell().info(Jason.encode!(report))
    else
      report_total(Report.total(report))
    end
  end

  defp check_modules_plain(env, modules, opts) do
    modules
    |> Enum.reduce_while([], fn module, reports ->
      case Theorem.check_all(module, env) do
        {:ok, theorems} ->
          report = module_report(module, theorems, env, opts)
          maybe_print_module(report, opts)
          {:cont, [report | reports]}

        {:error, {name, error}} ->
          Mix.shell().error("✗ #{inspect(module)} failed at #{name}\n")
          Mix.raise(Exception.message(error))
      end
    end)
    |> Enum.reverse()
    |> Report.new()
  end

  defp check_modules_installed(env, modules, opts) do
    modules
    |> Enum.reduce_while({env, []}, fn module, {env, reports} ->
      case Theorem.add_all_to_env(module, env) do
        {:ok, env, theorems} ->
          report = module_report(module, theorems, env, opts, installed?: true)
          maybe_print_module(report, opts)
          {:cont, {env, [report | reports]}}

        {:error, {name, error}} ->
          Mix.shell().error("✗ #{inspect(module)} failed at #{name}\n")
          Mix.raise(Exception.message(error))
      end
    end)
    |> then(fn {_env, reports} -> reports end)
    |> Enum.reverse()
    |> Report.new()
  end

  defp module_report(module, theorems, env, opts, extra \\ []) do
    installed? = Keyword.get(extra, :installed?, false)

    axiom_list =
      if Keyword.get(opts, :axioms, false), do: sorted_axioms(module_axioms(theorems, env))

    ModuleReport.new(module, theorems, installed?: installed?, axioms: axiom_list)
  end

  defp maybe_print_module(report, opts) do
    unless Keyword.get(opts, :json, false) do
      print_module(report)
    end
  end

  defp print_module(report) do
    suffixes = module_suffixes(report)

    Mix.shell().info(
      "✓ #{inspect(ModuleReport.module(report))} (#{ModuleReport.theorem_count(report)} theorem(s)#{suffixes})"
    )
  end

  defp module_suffixes(report) do
    [installed_suffix(ModuleReport.installed?(report)), axiom_suffix(ModuleReport.axioms(report))]
    |> Enum.reject(&(&1 == ""))
    |> case do
      [] -> ""
      suffixes -> [", " | Enum.intersperse(suffixes, ", ")]
    end
  end

  defp installed_suffix(true), do: "installed"
  defp installed_suffix(false), do: ""

  defp axiom_suffix(nil), do: ""
  defp axiom_suffix(axioms), do: "axioms: #{format_axioms(axioms)}"

  defp module_axioms(theorems, env) do
    Enum.reduce(theorems, MapSet.new(), fn theorem, axioms ->
      case Theorem.axioms(env, theorem) do
        {:ok, theorem_axioms} -> MapSet.union(axioms, theorem_axioms)
      end
    end)
  end

  defp sorted_axioms(axioms), do: Enum.sort(axioms)

  defp format_axioms([]), do: "none"
  defp format_axioms(axioms), do: Enum.map_join(axioms, ", ", &Atom.to_string/1)

  defp report_total(count) do
    Mix.shell().info("\nChecked #{count} theorem(s).")
  end
end
