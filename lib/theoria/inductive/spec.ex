defmodule Theoria.Inductive.Spec do
  @moduledoc "Structured description of an inductive family."

  alias Theoria.Inductive.{Constructor, Parameter, Recursor}
  alias Theoria.Term

  @enforce_keys [:name, :type, :constructors]
  defstruct [
    :name,
    :type,
    constructors: [],
    universe_params: [],
    parameters: [],
    indices: [],
    recursors: []
  ]

  @type t :: %__MODULE__{
          name: atom(),
          type: Term.t(),
          constructors: [Constructor.t()],
          universe_params: [atom()],
          parameters: [Parameter.t()],
          indices: [Term.t()],
          recursors: [Recursor.t()]
        }

  @spec new(atom(), Term.t(), keyword()) :: t()
  def new(name, type, opts \\ []) when is_atom(name) and is_list(opts) do
    %__MODULE__{
      name: name,
      type: type,
      constructors: Keyword.get(opts, :constructors, []),
      universe_params: Keyword.get(opts, :universe_params, Keyword.get(opts, :universes, [])),
      parameters: Enum.map(Keyword.get(opts, :parameters, []), &cast_parameter/1),
      indices: Keyword.get(opts, :indices, []),
      recursors: Keyword.get(opts, :recursors, [])
    }
  end

  @spec parameter(t(), atom(), Term.t()) :: t()
  def parameter(%__MODULE__{parameters: parameters} = spec, name, type) when is_atom(name) do
    %__MODULE__{spec | parameters: parameters ++ [%Parameter{name: name, type: type}]}
  end

  @spec constructor(t(), atom(), Term.t()) :: t()
  def constructor(%__MODULE__{constructors: constructors} = spec, name, type)
      when is_atom(name) do
    %__MODULE__{spec | constructors: constructors ++ [%Constructor{name: name, type: type}]}
  end

  @spec recursor(t(), atom(), Term.t(), Theoria.Env.Reduction.t()) :: t()
  def recursor(%__MODULE__{recursors: recursors} = spec, name, type, reduction)
      when is_atom(name) do
    %__MODULE__{
      spec
      | recursors: recursors ++ [%Recursor{name: name, type: type, reduction: reduction}]
    }
  end

  defp cast_parameter(%Parameter{} = parameter), do: parameter
  defp cast_parameter({name, type}) when is_atom(name), do: %Parameter{name: name, type: type}
  defp cast_parameter(other), do: other
end
