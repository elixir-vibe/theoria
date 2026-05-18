defmodule Mix.Tasks.Theoria.Simp do
  @moduledoc """
  Runs small built-in simplification examples.
  """

  use Mix.Task

  alias Theoria.Equation.Identity
  alias Theoria.Prelude
  alias Theoria.Pretty
  alias Theoria.Simp
  alias Theoria.Term

  @shortdoc "Runs generated-equation simplification examples"

  @impl true
  def run(args) do
    Mix.Task.run("app.start")

    case OptionParser.parse(args, strict: [examples: :boolean, prove: :boolean]) do
      {opts, [], []} ->
        run_examples(opts)

      {_opts, _args, invalid} ->
        Mix.raise("invalid option(s): #{format_invalid_options(invalid)}")
    end
  end

  defp run_examples(opts) do
    {:ok, env} = Prelude.env()
    Mix.shell().info("simplification examples:")

    Enum.each(examples(), fn {name, term} ->
      result = Simp.normalize(env, term, prove: Keyword.get(opts, :prove, false))
      Mix.shell().info("  #{name}: #{Pretty.term(term)} ↦ #{Pretty.term(result.term)}")

      Mix.shell().info(
        "    steps: #{Enum.map_join(result.steps, ", ", &Identity.format_declaration(&1.rule))}"
      )

      if result.realized do
        Mix.shell().info("    proof: checked #{Identity.format(result.realized.identity)}")
      end
    end)
  end

  defp examples do
    one = Term.app(Term.const(:succ), zero())
    bool_not_true = Term.app(Term.const(:bool_not), Term.const(true))
    nat_add_zero = Term.const(:nat_add) |> Term.app(zero()) |> Term.app(one)

    list_append_nil =
      Term.const(:list_append, [1])
      |> Term.app(nat())
      |> Term.app(list_nil())
      |> Term.app(list_nil())

    [
      {:bool_not_true, bool_not_true},
      {:nat_add_zero, nat_add_zero},
      {:list_append_nil, list_append_nil}
    ]
  end

  defp format_invalid_options(invalid) do
    Enum.map_join(invalid, ", ", fn {option, _value} -> option end)
  end

  defp nat, do: Term.const(:Nat)
  defp zero, do: Term.const(:zero)
  defp list_nil, do: Term.app(Term.const(:list_nil, [1]), nat())
end
