defmodule Theoria.Validation.DefeqCheck do
  @moduledoc "A Theoria-owned definitional-equality validation check."

  alias Theoria.Env
  alias Theoria.Normalize
  alias Theoria.Term

  @enforce_keys [:name, :left, :right]
  defstruct [:name, :left, :right, category: :defeq]

  @type t :: %__MODULE__{
          name: String.t(),
          category: atom(),
          left: Term.t(),
          right: Term.t()
        }

  @doc "Builds a definitional-equality check."
  @spec new(atom(), String.t(), Term.t(), Term.t()) :: t()
  def new(category, name, left, right) when is_atom(category) and is_binary(name) do
    %__MODULE__{category: category, name: name, left: left, right: right}
  end

  @doc "Checks the equality in Theoria's own normalizer."
  @spec check(Env.t(), t()) :: :ok | {:error, t()}
  def check(%Env{} = env, %__MODULE__{left: left, right: right} = check) do
    if Normalize.defeq?(env, left, right), do: :ok, else: {:error, check}
  end
end

defimpl Theoria.Validation.Checkable, for: Theoria.Validation.DefeqCheck do
  alias Theoria.Validation.DefeqCheck

  def check(%DefeqCheck{} = check, env), do: DefeqCheck.check(env, check)
end
