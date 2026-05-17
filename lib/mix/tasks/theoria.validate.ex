defmodule Mix.Tasks.Theoria.Validate do
  @moduledoc """
  Validates Theoria's native theorem, defeq, and inductive corpus.
  """

  use Mix.Task

  alias Theoria.Equation.{Info, Lemma}
  alias Theoria.Validation
  alias Theoria.Validation.{Corpus, Options, Report}

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

        Mix.shell().info("✓ equation metadata: #{Report.equation_count(result)} definition(s)")

        print_equations(result, opts)

      {:error, reason} ->
        Mix.raise(format_error(reason))
    end
  end

  @doc false
  def __parse_args__(args), do: parse_args(args)

  defp parse_args(args) do
    {opts, _argv, invalid} =
      OptionParser.parse(args,
        strict: [only: :keep, axioms: :boolean, equations: :boolean, verbose: :boolean]
      )

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

  defp print_equations(result, opts) do
    if Keyword.get(opts, :equations, false) do
      Mix.shell().info("\nequations:")
      Enum.each(result.equations, &print_equation(&1, opts))
    end
  end

  defp print_equation(equation, opts) do
    Mix.shell().info("  #{Info.summary(equation)}")

    if Keyword.get(opts, :verbose, false) do
      Enum.each(Lemma.generated_for(equation), &Mix.shell().info("    #{&1.name}"))
    end
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
