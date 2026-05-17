defmodule Mix.Tasks.Theoria.Lean.Check do
  @moduledoc """
  Generates a Lean oracle file from Theoria checks and asks Lean to validate it.

  This task is contributor-only. Lean is not required to use Theoria as a
  library.
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

    with {:ok, lean_module, count} <- Corpus.build(),
         source = LeanModule.render(lean_module),
         path = Keyword.get(opts, :path, Path.join(["_build", "theoria_lean", "oracle.lean"])),
         {:ok, result} <- Oracle.run(source, Keyword.put(opts, :path, path)) do
      Mix.shell().info("  #{result.path}")
      Mix.shell().info("\n✓ Lean accepted #{count} check(s).")
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

        Lean output:
        #{output}
        """)

      {:error, reason} ->
        Mix.raise("failed to generate Lean oracle: #{inspect(reason)}")
    end
  end

  defp parse_args(args) do
    {opts, _argv, invalid} = OptionParser.parse(args, strict: [path: :string, lean: :string])

    if invalid != [] do
      Mix.raise(
        "invalid option(s): #{Enum.map_join(invalid, ", ", fn {option, _value} -> option end)}"
      )
    end

    opts
  end
end
