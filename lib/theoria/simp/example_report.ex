defmodule Theoria.Simp.ExampleReport do
  @moduledoc "Structured report for one built-in simplification example."

  @type t :: %__MODULE__{
          name: atom(),
          stopped: boolean(),
          proof_checked: boolean(),
          result: Theoria.Simp.Result.t()
        }

  @enforce_keys [:name, :stopped, :proof_checked, :result]
  defstruct @enforce_keys

  @doc "Builds an example report from a simplifier result."
  @spec new(atom(), Theoria.Simp.Result.t()) :: t()
  def new(name, result) do
    %__MODULE__{
      name: name,
      stopped: result.stopped,
      proof_checked: not is_nil(result.realized),
      result: result
    }
  end

  @doc "Returns the example name."
  @spec name(t()) :: atom()
  def name(%__MODULE__{name: name}), do: name

  @doc "Returns true if simplification stopped before exhausting rules."
  @spec stopped?(t()) :: boolean()
  def stopped?(%__MODULE__{stopped: stopped}), do: stopped

  @doc "Returns true if a generated proof artifact was checked."
  @spec proof_checked?(t()) :: boolean()
  def proof_checked?(%__MODULE__{proof_checked: proof_checked}), do: proof_checked

  @doc "Returns the underlying simplifier result."
  @spec result(t()) :: Theoria.Simp.Result.t()
  def result(%__MODULE__{result: result}), do: result
end
