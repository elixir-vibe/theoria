defmodule Theoria.Env do
  @moduledoc """
  Kernel environment containing checked constants and definitions.
  """

  alias Theoria.Env.Constant
  alias Theoria.Term

  defstruct constants: %{}, declarations: []

  @type t :: %__MODULE__{constants: %{atom() => Constant.t()}, declarations: [atom()]}

  @spec new() :: t()
  def new, do: %__MODULE__{}

  @spec fetch(t(), atom()) :: {:ok, Constant.t()} | :error
  def fetch(%__MODULE__{constants: constants}, name) when is_atom(name) do
    Map.fetch(constants, name)
  end

  @spec put_constant(t(), atom(), Term.t()) :: t()
  def put_constant(%__MODULE__{constants: constants} = env, name, type) when is_atom(name) do
    %{
      env
      | constants: Map.put(constants, name, %Constant{type: type}),
        declarations: put_order(env, name)
    }
  end

  @spec put_definition(t(), atom(), Term.t(), Term.t()) :: t()
  def put_definition(%__MODULE__{constants: constants} = env, name, type, value)
      when is_atom(name) do
    %{
      env
      | constants:
          Map.put(constants, name, %Constant{
            type: type,
            value: value,
            kind: :definition,
            reducible?: true
          }),
        declarations: put_order(env, name)
    }
  end

  @spec put_theorem(t(), atom(), Term.t(), Term.t()) :: t()
  def put_theorem(%__MODULE__{constants: constants} = env, name, type, proof)
      when is_atom(name) do
    %{
      env
      | constants:
          Map.put(constants, name, %Constant{
            type: type,
            value: proof,
            kind: :theorem,
            reducible?: false
          }),
        declarations: put_order(env, name)
    }
  end

  @doc "Returns declaration names in insertion order."
  @spec declarations(t()) :: [atom()]
  def declarations(%__MODULE__{declarations: declarations}), do: declarations

  defp put_order(%__MODULE__{declarations: declarations}, name) do
    if name in declarations do
      declarations
    else
      declarations ++ [name]
    end
  end
end
