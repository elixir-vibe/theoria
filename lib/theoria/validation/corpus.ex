defmodule Theoria.Validation.Corpus do
  @moduledoc "Theoria-owned validation corpus consumed by local checks and external oracles."

  alias Theoria.Validation.DefeqChecks

  @library_validations %{
    logic: Theoria.Library.Logic.Validation,
    equality: Theoria.Library.Equality.Validation,
    bool: Theoria.Library.Bool.Validation,
    nat: Theoria.Library.Nat.Validation,
    list: Theoria.Library.List.Validation,
    vec: Theoria.Library.Vec.Validation
  }

  @builtin_categories [:logic, :equality, :bool, :nat, :list, :vec]
  @valid_categories @builtin_categories ++ [:defeq, :inductives]

  @enforce_keys [:categories, :theorem_checks, :theorem_modules, :defeq_checks, :inductive_checks]
  defstruct [:categories, :theorem_checks, :theorem_modules, :defeq_checks, :inductive_checks]

  @type t :: %__MODULE__{
          categories: [atom()],
          theorem_checks: [Theoria.Validation.TheoremModuleCheck.t()],
          theorem_modules: [module()],
          defeq_checks: [Theoria.Validation.DefeqCheck.t()],
          inductive_checks: [Theoria.Validation.InductiveCheck.t()]
        }

  @doc "Returns theorem modules included in the default validation corpus."
  @spec builtin_theorem_modules() :: [module()]
  def builtin_theorem_modules,
    do: Enum.map(library_checks(@builtin_categories), & &1.theorem.module)

  @doc "Returns valid validation categories."
  @spec valid_categories() :: [atom()]
  def valid_categories, do: @valid_categories

  @doc "Builds a validation corpus."
  @spec build(keyword()) :: t()
  def build(opts \\ []) do
    categories = Keyword.get(opts, :only) || @valid_categories
    library_categories = categories -- [:defeq, :inductives]
    library_checks = library_checks(library_categories)
    theorem_checks = Enum.map(library_checks, & &1.theorem)

    %__MODULE__{
      categories: categories,
      theorem_checks: theorem_checks,
      theorem_modules: Enum.map(theorem_checks, & &1.module),
      defeq_checks: defeq_checks(categories, library_checks),
      inductive_checks: inductive_checks(categories, library_checks)
    }
  end

  defp library_checks(categories),
    do: Enum.map(categories, &Map.fetch!(@library_validations, &1).checks())

  defp defeq_checks(categories, library_checks) do
    cond do
      :defeq in categories -> DefeqChecks.all()
      categories == [] -> []
      true -> library_checks |> Enum.flat_map(& &1.defeq) |> Enum.uniq_by(& &1.name)
    end
  end

  defp inductive_checks(categories, library_checks) do
    cond do
      :inductives in categories -> all_inductive_checks()
      categories == [] or categories == [:defeq] -> []
      true -> library_checks |> Enum.flat_map(& &1.inductive) |> Enum.uniq_by(& &1.name)
    end
  end

  defp all_inductive_checks do
    @builtin_categories
    |> library_checks()
    |> Enum.flat_map(& &1.inductive)
    |> Enum.uniq_by(& &1.name)
  end
end
