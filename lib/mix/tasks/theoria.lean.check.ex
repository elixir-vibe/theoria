defmodule Mix.Tasks.Theoria.Lean.Check do
  @moduledoc """
  Generates a Lean oracle file from Theoria checks and asks Lean to validate it.

  Use `--only equality`, `--only bool,nat,list`, or `--only defeq` to run a
  smaller corpus while developing encoders. This task is contributor-only. Lean
  is not required to use Theoria as a library.
  """

  use Mix.Task

  alias Theoria.Lean.Corpus
  alias Theoria.Lean.Module, as: LeanModule
  alias Theoria.Lean.Oracle

  @shortdoc "Checks Theoria's Lean oracle corpus"

  @impl true
  def run(args) do
    Mix.Task.run("app.start")

    opts = parse_args(args)

    Mix.shell().info("Generating Lean oracle corpus...")

    with {:ok, lean_module, stats} <- Corpus.build(only: Keyword.get(opts, :only)),
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
        "\nOpen:\n  #{path}:#{line}:#{column}\n\nTry narrowing the corpus, for example:\n  mix theoria.lean.check --only list --path /tmp/theoria_oracle.lean"

      _none ->
        ""
    end
  end

  defp parse_args(args) do
    {opts, _argv, invalid} =
      OptionParser.parse(args, strict: [path: :string, lean: :string, only: :keep])

    if invalid != [] do
      Mix.raise(
        "invalid option(s): #{Enum.map_join(invalid, ", ", fn {option, _value} -> option end)}"
      )
    end

    Keyword.update(opts, :only, Corpus.valid_categories(), &parse_only!/1)
  end

  defp parse_only!(values) do
    values
    |> List.wrap()
    |> Enum.flat_map(&String.split(&1, ",", trim: true))
    |> Enum.map(&parse_category!/1)
  end

  defp parse_category!(value) do
    category = Enum.find(Corpus.valid_categories(), &(Atom.to_string(&1) == value))

    if category do
      category
    else
      valid = Enum.map_join(Corpus.valid_categories(), ", ", &Atom.to_string/1)
      Mix.raise("invalid --only value: #{value}. Expected one of: #{valid}")
    end
  end
end
