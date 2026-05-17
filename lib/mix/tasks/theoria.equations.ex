defmodule Mix.Tasks.Theoria.Equations do
  @moduledoc """
  Lists generated equation lemmas for definitions with stored equation metadata.
  """

  use Mix.Task

  alias Theoria.Equation.{Eqns, Info, Lemma, MatcherEqns}
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

    Enum.each(equations, &print_equation/1)
  end

  defp print_equation(%Info{} = info) do
    Mix.shell().info("  #{Info.summary(info)}")
    print_matcher(info)
    print_unfold(info)
    print_lemmas(Lemma.generated_for(info))
    print_matcher_equations(MatcherEqns.generated(info))
  end

  defp print_lemmas(lemmas) do
    Enum.each(lemmas, fn lemma ->
      Mix.shell().info("    #{lemma.name}")
    end)
  end

  defp print_matcher_equations([]), do: :ok

  defp print_matcher_equations(matcher_equations) do
    Mix.shell().info("    matcher equations:")

    Enum.each(matcher_equations, fn equation ->
      Mix.shell().info("      #{equation.name}")
    end)
  end

  defp print_matcher(%Info{matcher: nil}), do: :ok

  defp print_matcher(%Info{} = info) do
    Mix.shell().info("    matcher: #{info.matcher.name}")

    if info.matcher.discriminants != [] do
      Mix.shell().info("    discriminants:")

      info.matcher.discriminants
      |> Enum.with_index()
      |> Enum.each(fn {discriminant, index} ->
        name = discriminant.name || :anonymous
        position = discriminant.position || index

        Mix.shell().info(
          "      #{index}: #{name} position=#{position} family=#{discriminant.family}"
        )
      end)
    end

    Mix.shell().info("    alternatives:")

    Enum.each(info.matcher.alternatives, fn alternative ->
      Mix.shell().info("      #{alternative.constructor} fields=#{alternative.num_fields}")
    end)
  end

  defp print_unfold(%Info{} = info) do
    Mix.shell().info("    unfold: #{Lemma.unfold_for(info).name}")
  end

  defp install_equations(env, equations) do
    equations
    |> Enum.reduce_while({env, 0}, fn info, {env, count} ->
      case Eqns.install(env, info.name) do
        {:ok, env, theorems} -> {:cont, {env, count + length(theorems)}}
        {:error, reason} -> Mix.raise("failed to install #{info.name}: #{inspect(reason)}")
      end
    end)
    |> then(fn {_env, count} -> Mix.shell().info("\nInstalled #{count} equation theorem(s).") end)
  end
end
