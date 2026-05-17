defmodule Mix.Tasks.Theoria.Check do
  @moduledoc """
  Checks Theoria theorem modules against the standard prelude.
  """

  use Mix.Task

  alias Theoria.Library.{Bool, Equality, List, Logic, Nat, Vec}
  alias Theoria.Theorem

  @shortdoc "Checks Theoria theorem modules"

  @theorem_modules [
    Logic.Theorems,
    Equality.Theorems,
    Bool.Theorems,
    Nat.Theorems,
    List.Theorems,
    Vec.Theorems
  ]

  @impl true
  def run(args) do
    Mix.Task.run("app.start")

    Mix.shell().info("Checking Theoria theorem modules...\n")

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
    case OptionParser.parse(args, strict: [install: :boolean, axioms: :boolean]) do
      {opts, module_args, []} ->
        {:ok, opts, module_args}

      {_opts, _module_args, invalid} ->
        {:error, "invalid option(s): #{format_invalid_options(invalid)}"}
    end
  end

  defp format_invalid_options(invalid) do
    Enum.map_join(invalid, ", ", fn {option, _value} -> option end)
  end

  defp theorem_modules([]), do: {:ok, @theorem_modules}

  defp theorem_modules(args) do
    args
    |> Enum.map(&Module.concat([&1]))
    |> Enum.reduce_while({:ok, []}, fn module, {:ok, modules} ->
      case load_theorem_module(module) do
        :ok -> {:cont, {:ok, [module | modules]}}
        {:error, message} -> {:halt, {:error, message}}
      end
    end)
    |> then(fn
      {:ok, modules} -> {:ok, Enum.reverse(modules)}
      {:error, message} -> {:error, message}
    end)
  end

  defp load_theorem_module(module) do
    with {:module, ^module} <- Code.ensure_loaded(module),
         true <- function_exported?(module, :__theoria_theorems__, 0) do
      :ok
    else
      {:error, _reason} -> {:error, "could not load theorem module #{inspect(module)}"}
      false -> {:error, "#{inspect(module)} is not a Theoria theorem module"}
    end
  end

  defp check_modules(env, modules, opts) do
    if Keyword.get(opts, :install, false) do
      check_modules_installed(env, modules, opts)
    else
      check_modules_plain(env, modules, opts)
    end
  end

  defp check_modules_plain(env, modules, opts) do
    modules
    |> Enum.reduce_while(0, fn module, count ->
      case Theorem.check_all(module, env) do
        {:ok, theorems} ->
          report_module(module, theorems, env, opts)
          {:cont, count + length(theorems)}

        {:error, {name, error}} ->
          Mix.shell().error("✗ #{inspect(module)} failed at #{name}\n")
          Mix.raise(Exception.message(error))
      end
    end)
    |> report_total()
  end

  defp check_modules_installed(env, modules, opts) do
    modules
    |> Enum.reduce_while({env, 0}, fn module, {env, count} ->
      case Theorem.add_all_to_env(module, env) do
        {:ok, env, theorems} ->
          report_module(module, theorems, env, opts, installed?: true)
          {:cont, {env, count + length(theorems)}}

        {:error, {name, error}} ->
          Mix.shell().error("✗ #{inspect(module)} failed at #{name}\n")
          Mix.raise(Exception.message(error))
      end
    end)
    |> then(fn {_env, count} -> count end)
    |> report_total()
  end

  defp report_module(module, theorems, env, opts, extra \\ []) do
    installed? = Keyword.get(extra, :installed?, false)
    suffixes = module_suffixes(theorems, env, opts, installed?)
    Mix.shell().info("✓ #{inspect(module)} (#{length(theorems)} theorem(s)#{suffixes})")
  end

  defp module_suffixes(theorems, env, opts, installed?) do
    [installed_suffix(installed?), axiom_suffix(theorems, env, opts)]
    |> Enum.reject(&(&1 == ""))
    |> case do
      [] -> ""
      suffixes -> [", " | Enum.intersperse(suffixes, ", ")]
    end
  end

  defp installed_suffix(true), do: "installed"
  defp installed_suffix(false), do: ""

  defp axiom_suffix(theorems, env, opts) do
    if Keyword.get(opts, :axioms, false) do
      "axioms: #{format_axioms(module_axioms(theorems, env))}"
    else
      ""
    end
  end

  defp module_axioms(theorems, env) do
    Enum.reduce(theorems, MapSet.new(), fn theorem, axioms ->
      case Theorem.axioms(env, theorem) do
        {:ok, theorem_axioms} -> MapSet.union(axioms, theorem_axioms)
      end
    end)
  end

  defp format_axioms(axioms) do
    if MapSet.size(axioms) == 0 do
      "none"
    else
      axioms
      |> Enum.sort()
      |> Enum.map_join(", ", &Atom.to_string/1)
    end
  end

  defp report_total(count) do
    Mix.shell().info("\nChecked #{count} theorem(s).")
  end
end
