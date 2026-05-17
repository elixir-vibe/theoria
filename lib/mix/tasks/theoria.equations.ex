defmodule Mix.Tasks.Theoria.Equations do
  @moduledoc """
  Lists generated equation lemmas for definitions with stored equation metadata.
  """

  use Mix.Task

  alias Theoria.Equation.Info
  alias Theoria.Equation.Lemma
  alias Theoria.Prelude

  @shortdoc "Lists and optionally installs generated equation lemmas"

  @impl true
  def run(args) do
    Mix.Task.run("app.start")

    with {:ok, opts, names} <- parse_args(args),
         {:ok, env} <- Prelude.env() do
      equations = select_equations(env, names)
      print_equations(equations)

      if Keyword.get(opts, :install, false) do
        install_equations(env, equations)
      end
    else
      {:error, %Theoria.Error{} = error} ->
        Mix.raise("failed to build Theoria prelude:\n\n#{Exception.message(error)}")

      {:error, message} when is_binary(message) ->
        Mix.raise(message)
    end
  end

  defp parse_args(args) do
    case OptionParser.parse(args, strict: [install: :boolean]) do
      {opts, names, []} ->
        {:ok, opts, Enum.map(names, &String.to_atom/1)}

      {_opts, _names, invalid} ->
        {:error, "invalid option(s): #{format_invalid_options(invalid)}"}
    end
  end

  defp format_invalid_options(invalid) do
    Enum.map_join(invalid, ", ", fn {option, _value} -> option end)
  end

  defp select_equations(env, []), do: Info.all(env)

  defp select_equations(env, names) do
    Enum.map(names, fn name ->
      case Info.fetch(env, name) do
        {:ok, info} -> info
        {:error, reason} -> Mix.raise("unknown equation definition #{name}: #{inspect(reason)}")
      end
    end)
  end

  defp print_equations([]), do: Mix.shell().info("No equation metadata found.")

  defp print_equations(equations) do
    Mix.shell().info("equations:")

    Enum.each(equations, fn info ->
      lemmas = Lemma.generated_for(info)
      Mix.shell().info("  #{Info.summary(info)}")

      Enum.each(lemmas, fn lemma ->
        Mix.shell().info("    #{lemma.name}")
      end)
    end)
  end

  defp install_equations(env, equations) do
    equations
    |> Enum.reduce_while({env, 0}, fn info, {env, count} ->
      case Lemma.add_generated_to_env(env, info) do
        {:ok, env, theorems} -> {:cont, {env, count + length(theorems)}}
        {:error, reason} -> Mix.raise("failed to install #{info.name}: #{inspect(reason)}")
      end
    end)
    |> then(fn {_env, count} -> Mix.shell().info("\nInstalled #{count} equation theorem(s).") end)
  end
end
