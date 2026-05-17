defmodule Theoria.Validation.TheoremModuleCheck do
  @moduledoc "A validation check for a Theoria theorem module."

  @enforce_keys [:module, :category]
  defstruct [:module, :category]

  @type t :: %__MODULE__{module: module(), category: atom()}

  @doc "Builds a theorem module validation check."
  @spec new(atom(), module()) :: t()
  def new(category, module) when is_atom(category) and is_atom(module) do
    %__MODULE__{category: category, module: module}
  end
end

defimpl Theoria.Validation.Checkable, for: Theoria.Validation.TheoremModuleCheck do
  alias Theoria.Theorem
  alias Theoria.Validation.TheoremModuleCheck

  def check(%TheoremModuleCheck{module: module}, env) do
    case Theorem.check_all(module, env) do
      {:ok, _theorems} -> :ok
      {:error, error} -> {:error, error}
    end
  end
end
