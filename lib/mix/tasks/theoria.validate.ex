defmodule Mix.Tasks.Theoria.Validate do
  @moduledoc """
  Validates Theoria's native theorem, defeq, and inductive corpus.
  """

  use Mix.Task

  alias Theoria.Validation
  alias Theoria.Validation.{Corpus, Options}

  @shortdoc "Validates Theoria's native corpus"

  @impl true
  def run(args) do
    Mix.Task.run("app.start")

    opts = parse_args(args)
    corpus = Corpus.build(only: Keyword.get(opts, :only))

    Mix.shell().info("Validating Theoria corpus...\n")

    case Validation.check(corpus) do
      {:ok, result} ->
        Mix.shell().info(
          "✓ theorem modules: #{result.theorem_count} theorem(s)#{axiom_suffix(result, opts)}"
        )

        Mix.shell().info("✓ defeq checks: #{result.defeq_count} check(s)")
        Mix.shell().info("✓ inductive specs: #{result.inductive_count} check(s)")
        Mix.shell().info("✓ equation metadata: #{result.equation_count} definition(s)")

      {:error, reason} ->
        Mix.raise(format_error(reason))
    end
  end

  @doc false
  def __parse_args__(args), do: parse_args(args)

  defp parse_args(args) do
    {opts, _argv, invalid} = OptionParser.parse(args, strict: [only: :keep, axioms: :boolean])

    if invalid != [] do
      Mix.raise(
        "invalid option(s): #{Enum.map_join(invalid, ", ", fn {option, _value} -> option end)}"
      )
    end

    Keyword.update(
      opts,
      :only,
      Corpus.valid_categories(),
      &Options.parse_only!(&1, Corpus.valid_categories())
    )
  end

  defp axiom_suffix(result, opts) do
    if Keyword.get(opts, :axioms, false) do
      ", axioms: #{format_axioms(result.axioms)}"
    else
      ""
    end
  end

  defp format_axioms(axioms) do
    if MapSet.size(axioms) == 0 do
      "none"
    else
      axioms |> Enum.sort() |> Enum.map_join(", ", &Atom.to_string/1)
    end
  end

  defp format_error({%Theoria.Validation.TheoremModuleCheck{module: module}, {name, error}}) do
    "theorem validation failed at #{inspect(module)}.#{name}:\n\n#{Exception.message(error)}"
  end

  defp format_error({%Theoria.Validation.DefeqCheck{} = check, _failed}) do
    "defeq validation failed at #{check.name}"
  end

  defp format_error({%Theoria.Validation.InductiveCheck{} = check, %Theoria.Error{} = error}) do
    "inductive validation failed at #{check.name}:\n\n#{Exception.message(error)}"
  end

  defp format_error(reason), do: "validation failed: #{inspect(reason)}"
end
