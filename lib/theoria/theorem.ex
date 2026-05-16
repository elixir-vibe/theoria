defmodule Theoria.Theorem do
  @moduledoc "A theorem accepted by the trusted kernel."

  alias Theoria.Env
  alias Theoria.Term

  @enforce_keys [:name, :type, :proof]
  defstruct [:name, :type, :proof]

  @type t :: %__MODULE__{name: atom(), type: Term.t(), proof: Term.t()}

  @doc "Checks every theorem registered by a `use Theoria.DSL` theorem module."
  @spec check_all(module(), Env.t()) :: {:ok, [t()]} | {:error, {atom(), Theoria.Error.t()}}
  def check_all(module, %Env{} = env) when is_atom(module) do
    module.__theoria_theorems__()
    |> Enum.reduce_while({:ok, []}, fn name, {:ok, checked} ->
      theorem_fun = String.to_existing_atom("#{name}_theorem")

      case apply(module, theorem_fun, [env]) do
        {:ok, %__MODULE__{} = theorem} -> {:cont, {:ok, [theorem | checked]}}
        {:error, error} -> {:halt, {:error, {name, error}}}
      end
    end)
    |> reverse_checked()
  end

  defp reverse_checked({:ok, checked}), do: {:ok, Enum.reverse(checked)}
  defp reverse_checked({:error, {_name, _error}} = error), do: error
end
