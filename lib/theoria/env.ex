defmodule Theoria.Env do
  @moduledoc """
  Kernel environment containing checked constants and definitions.
  """

  alias Theoria.Env.Constant
  alias Theoria.Term

  defstruct constants: %{}

  @type t :: %__MODULE__{constants: %{atom() => Constant.t()}}

  @spec new() :: t()
  def new, do: %__MODULE__{}

  @spec fetch(t(), atom()) :: {:ok, Constant.t()} | :error
  def fetch(%__MODULE__{constants: constants}, name) when is_atom(name) do
    Map.fetch(constants, name)
  end

  @spec put_constant(t(), atom(), Term.t()) :: t()
  def put_constant(%__MODULE__{constants: constants} = env, name, type) when is_atom(name) do
    %{env | constants: Map.put(constants, name, %Constant{type: type})}
  end

  @spec put_definition(t(), atom(), Term.t(), Term.t()) :: t()
  def put_definition(%__MODULE__{constants: constants} = env, name, type, value)
      when is_atom(name) do
    %{env | constants: Map.put(constants, name, %Constant{type: type, value: value})}
  end
end
