defmodule Mix.Tasks.Theoria.Check do
  @moduledoc """
  Checks Theoria theorem modules against the standard prelude.
  """

  use Mix.Task

  alias Theoria.Library.{Bool, List, Logic, Nat}
  alias Theoria.Theorem

  @shortdoc "Checks Theoria theorem modules"

  @theorem_modules [
    Logic.Theorems,
    Bool.Theorems,
    Nat.Theorems,
    List.Theorems
  ]

  @impl true
  def run(_args) do
    Mix.Task.run("app.start")

    Mix.shell().info("Checking Theoria theorem modules...\n")

    case Theoria.Prelude.env() do
      {:ok, env} ->
        check_modules(env)

      {:error, error} ->
        Mix.raise("failed to build Theoria prelude:\n\n#{Exception.message(error)}")
    end
  end

  defp check_modules(env) do
    @theorem_modules
    |> Enum.reduce_while(0, fn module, count ->
      case Theorem.check_all(module, env) do
        {:ok, theorems} ->
          Mix.shell().info("✓ #{inspect(module)} (#{length(theorems)} theorem(s))")
          {:cont, count + length(theorems)}

        {:error, {name, error}} ->
          Mix.shell().error("✗ #{inspect(module)} failed at #{name}\n")
          Mix.raise(Exception.message(error))
      end
    end)
    |> report_total()
  end

  defp report_total(count) do
    Mix.shell().info("\nChecked #{count} theorem(s).")
  end
end
