defmodule Mix.Tasks.Theoria.Equations do
  @moduledoc """
  Lists generated equation lemmas for definitions with stored equation metadata.
  """

  use Mix.Task

  alias Theoria.Env
  alias Theoria.Equation.Matcher.Descriptor, as: MatcherDescriptor
  alias Theoria.Equation.Matcher.Eqns, as: MatcherEqns
  alias Theoria.Equation.Matcher.Info, as: MatcherMetadata

  alias Theoria.Equation.{
    Eqns,
    Extension,
    Identity,
    Info,
    Lemma
  }

  alias Theoria.Prelude

  @shortdoc "Lists and optionally installs generated equation lemmas"

  @impl true
  def run(args) do
    Mix.Task.run("app.start")

    with {:ok, opts, names} <- parse_args(args),
         {:ok, env} <- Prelude.env() do
      equations = select_equations(env, names)
      print_equations(env, equations)

      if Keyword.get(opts, :realize, false) do
        realize_equations(env, equations)
      end

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
    case OptionParser.parse(args, strict: [install: :boolean, realize: :boolean]) do
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

  defp print_equations(_env, []), do: Mix.shell().info("No equation metadata found.")

  defp print_equations(env, equations) do
    matchers = selected_matchers(env, equations)
    Mix.shell().info("matcher declarations: #{length(matchers)}")
    Mix.shell().info("registry entries: #{registry_entry_count(env, equations)}")
    Mix.shell().info("")
    print_equations(env, equations, :details)
  end

  defp print_equations(env, equations, :details) do
    Mix.shell().info("equations:")

    Enum.each(equations, &print_equation(env, &1))
  end

  defp print_equation(env, %Info{} = info) do
    Mix.shell().info("  #{Info.summary(info)}")
    print_matcher(env, info)
    print_unfold(info)
    print_lemmas(Lemma.generated_for(info))
    print_matcher_equations(MatcherEqns.generated(info))
  end

  defp print_lemmas(lemmas) do
    Enum.each(lemmas, fn lemma ->
      Mix.shell().info("    #{format_equation_name(lemma)}")
    end)
  end

  defp print_matcher_equations([]), do: :ok

  defp print_matcher_equations(matcher_equations) do
    Mix.shell().info("    matcher equations:")

    Enum.each(matcher_equations, fn equation ->
      Mix.shell().info("      #{format_equation_name(equation)}")
    end)
  end

  defp print_matcher(_env, %Info{matcher: nil}), do: :ok

  defp print_matcher(env, %Info{} = info) do
    Mix.shell().info("    matcher: #{info.matcher.name} #{matcher_details(env, info)}")
    print_descriptor(env, info)

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

  defp print_descriptor(_env, %Info{schema: nil}), do: :ok

  defp print_descriptor(env, %Info{} = info) do
    case MatcherDescriptor.from_env(env, info.schema, info.matcher) do
      {:ok, descriptor} ->
        indexed =
          if descriptor.indexed?,
            do: " indexed=true indices=#{length(descriptor.indices)}",
            else: ""

        Mix.shell().info(
          "    descriptor: family=#{descriptor.family}#{indexed} discrs=#{length(descriptor.discriminants)} alts=#{length(descriptor.alternatives)} recursor=#{descriptor.recursor}"
        )

      {:error, _reason} ->
        :ok
    end
  end

  defp matcher_details(env, %Info{} = info) do
    mode =
      case Env.fetch_matcher(env, info.matcher.name) do
        {:ok, matcher} -> matcher.mode
        :error -> :unknown
      end

    "mode=#{mode} arity=#{MatcherMetadata.arity(info.matcher)}"
  end

  defp print_unfold(%Info{} = info) do
    Mix.shell().info("    unfold: #{format_equation_name(Lemma.unfold_for(info))}")
  end

  defp registry_entry_count(env, equations) do
    ordinary_count =
      Enum.reduce(equations, 0, fn info, count ->
        count + 1 + length(Extension.equation_identities(info))
      end)

    matcher_count =
      env
      |> selected_matchers(equations)
      |> Enum.reduce(0, fn matcher, count ->
        count + length(Extension.matcher_equation_identities(env, matcher))
      end)

    ordinary_count + matcher_count
  end

  defp selected_matchers(env, equations) do
    source_names = MapSet.new(Enum.map(equations, & &1.name))

    env
    |> Env.matchers()
    |> Enum.filter(&MapSet.member?(source_names, &1.source))
  end

  defp format_equation_name(%{identity: %Identity{} = identity}), do: Identity.format(identity)
  defp format_equation_name(%{name: name}), do: Identity.format_declaration(name)

  defp realize_equations(env, equations) do
    equations
    |> Enum.reduce(0, fn info, count ->
      case Eqns.realize(env, info.name) do
        {:ok, artifacts} when is_list(artifacts) -> count + length(artifacts)
        {:ok, _artifact} -> count + 1
        {:error, reason} -> Mix.raise("failed to realize #{info.name}: #{inspect(reason)}")
      end
    end)
    |> then(&Mix.shell().info("\nRealized #{&1} equation artifact(s)."))
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
