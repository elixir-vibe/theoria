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

    case OptionParser.parse(args,
           strict: [examples: :boolean, json: :boolean, list: :boolean, prove: :boolean]
         ) do
      {opts, [], []} ->
        if Keyword.get(opts, :list, false),
          do: list_examples(),
          else: run_examples(opts, examples())

      {opts, names, []} ->
        run_examples(opts, select_examples(names))

      {_opts, _args, invalid} ->
        Mix.raise("invalid option(s): #{format_invalid_options(invalid)}")
    end
  end

  defp list_examples do
    examples()
    |> Keyword.keys()
    |> Enum.each(&Mix.shell().info(to_string(&1)))
  end

  defp run_examples(opts, examples) do
    {:ok, env} = Prelude.env()
    results = Enum.map(examples, &run_example(env, &1, opts))

    if Keyword.get(opts, :json, false) do
      Mix.shell().info(Jason.encode!(%{examples: Enum.map(results, &json_example/1)}))
    else
      Mix.shell().info("simplification examples:")
      Enum.each(results, &print_example/1)
    end
  end

  defp run_example(env, {name, term}, opts) do
    result =
      Simp.normalize(env, term,
        prove: Keyword.get(opts, :prove, false),
        realize: Keyword.get(opts, :realize, false)
      )

    %{name: name, term: term, result: result}
  end

  defp print_example(%{name: name, term: term, result: result}) do
    Mix.shell().info("  #{name}: #{Pretty.term(term)} ↦ #{Pretty.term(result.term)}")

    Mix.shell().info(
      "    steps: #{Enum.map_join(result.steps, ", ", &Identity.format_declaration(&1.rule))}"
    )

    if result.realized do
      Mix.shell().info("    proof: checked #{Identity.format(result.realized.identity)}")
    end
  end

  defp json_example(%{name: name, result: result}) do
    %{
      name: name,
      stopped: result.stopped,
      proof_checked: not is_nil(result.realized),
      result: result
    }
  end

  defp select_examples(names) do
    available = Map.new(examples(), fn {name, term} -> {Atom.to_string(name), {name, term}} end)

    Enum.map(names, fn name ->
      case Map.fetch(available, name) do
        {:ok, example} -> example
        :error -> Mix.raise("unknown simplification example #{name}")
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
