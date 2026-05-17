defmodule Theoria.Lean.Corpus do
  @moduledoc "Thin adapter from Theoria's validation corpus to Lean oracle modules."

  alias Theoria.Elaborator
  alias Theoria.Lean.Module, as: LeanModule
  alias Theoria.Validation.Corpus, as: ValidationCorpus

  @doc "Returns theorem modules included in the default validation corpus."
  @spec builtin_theorem_modules() :: [module()]
  def builtin_theorem_modules, do: ValidationCorpus.builtin_theorem_modules()

  @doc "Returns valid `--only` corpus categories."
  @spec valid_categories() :: [atom()]
  def valid_categories, do: ValidationCorpus.valid_categories()

  @doc "Builds the Lean oracle module from Theoria's validation corpus."
  @spec build(keyword()) :: {:ok, LeanModule.t(), LeanModule.stats()} | {:error, term()}
  def build(opts \\ []) do
    validation = ValidationCorpus.build(opts)

    with {:ok, module, _proof_count} <-
           add_theorem_modules(LeanModule.new(), validation.theorem_modules) do
      module = add_defeq_checks(module, validation.defeq_checks)
      {:ok, module, LeanModule.stats(module)}
    end
  end

  defp add_theorem_modules(module, theorem_modules) do
    Enum.reduce_while(theorem_modules, {:ok, module, 0}, fn theorem_module,
                                                            {:ok, module, count} ->
      case add_theorem_module(module, theorem_module) do
        {:ok, module, added} -> {:cont, {:ok, module, count + added}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp add_theorem_module(module, theorem_module) do
    theorem_module.__theoria_theorems__()
    |> Enum.reduce_while({:ok, module, 0}, fn theorem_name, {:ok, module, count} ->
      with {:ok, type} <-
             theorem_module
             |> apply(String.to_existing_atom("#{theorem_name}_type"), [])
             |> Elaborator.elaborate(),
           {:ok, proof} <-
             theorem_module
             |> apply(String.to_existing_atom("#{theorem_name}_proof"), [])
             |> Elaborator.elaborate() do
        name = "#{inspect(theorem_module)}.#{theorem_name}"
        {:cont, {:ok, LeanModule.add_proof_check(module, name, proof, type), count + 1}}
      else
        {:error, error} -> {:halt, {:error, {theorem_module, theorem_name, error}}}
      end
    end)
  end

  defp add_defeq_checks(module, checks) do
    Enum.reduce(checks, module, fn check, module ->
      LeanModule.add_defeq_check(module, check.name, check.left, check.right)
    end)
  end
end
