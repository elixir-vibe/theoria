defmodule Mix.Tasks.Theoria.Lean.Check do
  @moduledoc """
  Generates Lean source from Theoria validation data and asks Lean to validate it.

  Use `--only equality`, `--only bool,nat,list`, or `--only defeq` to run a
  smaller validation slice while developing encoders. This task is contributor-only.
  Lean is not required to use Theoria as a library.
  """

  use Mix.Task

  alias Theoria.Lean.Module, as: LeanModule
  alias Theoria.Lean.Oracle
  alias Theoria.Validation.Corpus
  alias Theoria.Validation.Options

  @lean_categories [:logic, :equality, :bool, :nat, :list, :vec, :defeq, :inductives]
  @shortdoc "Checks Theoria validation data with Lean"

  @impl true
  def run(args) do
    Mix.Task.run("app.start")

    opts = parse_args(args)

    categories = Keyword.get(opts, :only) || @lean_categories

    Mix.shell().info("Generating Lean validation oracle...")
    Mix.shell().info("  categories: #{Enum.join(categories, ", ")}")

    validation = Corpus.build(only: categories)

    with {:ok, lean_module} <- LeanModule.from_validation(validation),
         stats = LeanModule.stats(lean_module),
         source = LeanModule.render(lean_module),
         path = Keyword.get(opts, :path, Path.join(["_build", "theoria_lean", "oracle.lean"])),
         {:ok, result} <- Oracle.run(source, Keyword.put(opts, :path, path)) do
      Mix.shell().info("  #{result.path}")
      Mix.shell().info("\nLean: #{result.version}")
      Mix.shell().info("✓ proof checks: #{stats.proof}")
      Mix.shell().info("✓ defeq checks: #{stats.defeq}")
      Mix.shell().info("✓ total: #{stats.total}")
    else
      {:error, :lean_not_found} ->
        Mix.raise("""
        Lean executable not found.

        Install Lean with elan:
          curl https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh -sSf | sh

        This task is contributor-only and is not required to use Theoria.
        """)

      {:error, {:lean_failed, status, path, output}} ->
        Mix.raise("""
        Lean oracle failed with exit status #{status}.

        Generated file:
          #{path}
        #{location_hint(path, output)}

        Lean output:
        #{output}
        """)

      {:error, reason} ->
        Mix.raise("failed to generate Lean oracle: #{inspect(reason)}")
    end
  end

  defp location_hint(path, output) do
    case Regex.run(~r/:(\d+):(\d+): error/, output) do
      [_match, line, column] ->
        "\nOpen:\n  #{path}:#{line}:#{column}\n\nTry narrowing the validation slice, for example:\n  mix theoria.lean.check --only list --path /tmp/theoria_oracle.lean"

      _none ->
        ""
    end
  end

  @doc false
  def __parse_args__(args), do: parse_args(args)

  defp parse_args(args) do
    {opts, _argv, invalid} =
      OptionParser.parse(args, strict: [path: :string, lean: :string, only: :keep])

    if invalid != [] do
      Mix.raise(
        "invalid option(s): #{Enum.map_join(invalid, ", ", fn {option, _value} -> option end)}"
      )
    end

    Keyword.update(opts, :only, @lean_categories, &Options.parse_only!(&1, @lean_categories))
  end
end
