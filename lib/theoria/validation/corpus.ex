defmodule Theoria.Validation.Corpus do
  @moduledoc "Theoria-owned validation corpus consumed by local checks and external oracles."

  alias Theoria.Validation.DefeqChecks

  @theorem_modules %{
    equality: Theoria.Library.Equality.Theorems,
    bool: Theoria.Library.Bool.Theorems,
    nat: Theoria.Library.Nat.Theorems,
    list: Theoria.Library.List.Theorems,
    vec: Theoria.Library.Vec.Theorems
  }

  @builtin_categories [:equality, :bool, :nat, :list, :vec]
  @valid_categories @builtin_categories ++ [:defeq]

  @enforce_keys [:categories, :theorem_modules, :defeq_checks]
  defstruct [:categories, :theorem_modules, :defeq_checks]

  @type t :: %__MODULE__{
          categories: [atom()],
          theorem_modules: [module()],
          defeq_checks: [Theoria.Validation.DefeqCheck.t()]
        }

  @doc "Returns theorem modules included in the default validation corpus."
  @spec builtin_theorem_modules() :: [module()]
  def builtin_theorem_modules,
    do: Enum.map(@builtin_categories, &Map.fetch!(@theorem_modules, &1))

  @doc "Returns valid validation categories."
  @spec valid_categories() :: [atom()]
  def valid_categories, do: @valid_categories

  @doc "Builds a validation corpus."
  @spec build(keyword()) :: t()
  def build(opts \\ []) do
    categories = Keyword.get(opts, :only) || @valid_categories
    theorem_categories = Enum.filter(categories, &(&1 != :defeq))

    %__MODULE__{
      categories: categories,
      theorem_modules: theorem_modules(theorem_categories),
      defeq_checks: defeq_checks(categories)
    }
  end

  defp theorem_modules(categories) do
    Enum.map(categories, &Map.fetch!(@theorem_modules, &1))
  end

  defp defeq_checks(categories) do
    if :defeq in categories do
      DefeqChecks.all()
    else
      categories = MapSet.new(categories)
      Enum.filter(DefeqChecks.all(), &MapSet.member?(categories, &1.category))
    end
  end
end
