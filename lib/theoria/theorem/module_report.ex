defmodule Theoria.Theorem.ModuleReport do
  @moduledoc """
  Structured report for one checked theorem module.

  `mix theoria.theorems --json` encodes these reports with Jason. Text output is
  still intentionally concise, while JSON consumers can rely on this struct shape
  and accessor functions instead of parsing human output.
  """

  @type t :: %__MODULE__{
          module: module(),
          theorem_names: [atom()],
          theorem_count: non_neg_integer(),
          installed?: boolean(),
          axioms: [atom()] | nil
        }

  @enforce_keys [:module, :theorem_names, :theorem_count, :installed?]
  defstruct [:module, :theorem_names, :theorem_count, :installed?, axioms: nil]

  @doc "Builds a theorem module report from checked theorem structs."
  @spec new(module(), [Theoria.Theorem.t()], keyword()) :: t()
  def new(module, theorems, opts \\ []) do
    %__MODULE__{
      module: module,
      theorem_names: Enum.map(theorems, & &1.name),
      theorem_count: length(theorems),
      installed?: Keyword.get(opts, :installed?, false),
      axioms: Keyword.get(opts, :axioms)
    }
  end

  @doc "Returns the theorem module."
  @spec module(t()) :: module()
  def module(%__MODULE__{module: module}), do: module

  @doc "Returns checked theorem names in declaration order."
  @spec theorem_names(t()) :: [atom()]
  def theorem_names(%__MODULE__{theorem_names: theorem_names}), do: theorem_names

  @doc "Returns the number of checked theorems."
  @spec theorem_count(t()) :: non_neg_integer()
  def theorem_count(%__MODULE__{theorem_count: theorem_count}), do: theorem_count

  @doc "Returns true when theorems were installed into the environment during checking."
  @spec installed?(t()) :: boolean()
  def installed?(%__MODULE__{installed?: installed?}), do: installed?

  @doc "Returns the optional sorted axiom list for this module."
  @spec axioms(t()) :: [atom()] | nil
  def axioms(%__MODULE__{axioms: axioms}), do: axioms
end
