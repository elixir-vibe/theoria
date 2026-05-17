defmodule Theoria.Lean.Corpus do
  @moduledoc "Thin adapter from Theoria's validation corpus to Lean oracle modules."

  alias Theoria.Lean.Module, as: LeanModule
  alias Theoria.Validation.Corpus, as: ValidationCorpus

  @doc "Returns theorem modules included in the default validation corpus."
  @spec builtin_theorem_modules() :: [module()]
  def builtin_theorem_modules,
    do: ValidationCorpus.build(only: [:equality, :bool, :nat, :list, :vec]).theorem_modules

  @lean_categories [:equality, :bool, :nat, :list, :vec, :defeq, :inductives]

  @doc "Returns valid `--only` corpus categories supported by the Lean oracle."
  @spec valid_categories() :: [atom()]
  def valid_categories, do: @lean_categories

  @doc "Builds the Lean oracle module from Theoria's validation corpus."
  @spec build(keyword()) :: {:ok, LeanModule.t(), LeanModule.stats()} | {:error, term()}
  def build(opts \\ []) do
    validation = ValidationCorpus.build(only: Keyword.get(opts, :only) || @lean_categories)

    with {:ok, module} <- LeanModule.from_validation(validation) do
      {:ok, module, LeanModule.stats(module)}
    end
  end
end
