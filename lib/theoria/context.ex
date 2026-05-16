defmodule Theoria.Context do
  @moduledoc """
  Typing context for bound variables.

  Bindings are stored nearest-binder first. A binding's type is stored relative
  to the context where the binder was introduced. Lookup weakens the stored type
  into the current context.
  """

  alias Theoria.Term

  defstruct bindings: []

  @type binding :: {atom(), Term.t()}
  @type t :: %__MODULE__{bindings: [binding()]}

  @spec new() :: t()
  def new, do: %__MODULE__{}

  @spec push(t(), atom(), Term.t()) :: t()
  def push(%__MODULE__{bindings: bindings} = context, name, type) when is_atom(name) do
    %__MODULE__{context | bindings: [{name, type} | bindings]}
  end

  @spec fetch(t(), non_neg_integer()) :: {:ok, binding()} | :error
  def fetch(%__MODULE__{bindings: bindings}, index) when is_integer(index) and index >= 0 do
    case Enum.at(bindings, index) do
      nil -> :error
      {name, type} -> {:ok, {name, Term.shift(type, index + 1)}}
    end
  end

  @spec size(t()) :: non_neg_integer()
  def size(%__MODULE__{bindings: bindings}), do: length(bindings)
end
