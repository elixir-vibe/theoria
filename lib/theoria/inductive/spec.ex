defmodule Theoria.Inductive.Spec do
  @moduledoc "Structured description of an inductive family."

  alias Theoria.Inductive.{Constructor, Index, Parameter, Recursor}
  alias Theoria.Term

  @enforce_keys [:name, :type, :constructors]
  defstruct [
    :name,
    :type,
    constructors: [],
    universe_params: [],
    num_params: 0,
    parameters: [],
    indices: [],
    recursors: []
  ]

  @type t :: %__MODULE__{
          name: atom(),
          type: Term.t(),
          constructors: [Constructor.t()],
          universe_params: [atom()],
          num_params: non_neg_integer(),
          parameters: [Parameter.t()],
          indices: [Index.t()],
          recursors: [Recursor.t()]
        }

  @spec new(atom(), Term.t(), keyword()) :: t()
  def new(name, type, opts \\ []) when is_atom(name) and is_list(opts) do
    parameters = Enum.map(Keyword.get(opts, :parameters, []), &cast_parameter/1)

    %__MODULE__{
      name: name,
      type: type,
      constructors: Keyword.get(opts, :constructors, []),
      universe_params: Keyword.get(opts, :universe_params, Keyword.get(opts, :universes, [])),
      num_params: Keyword.get(opts, :num_params, length(parameters)),
      parameters: parameters,
      indices: Enum.map(Keyword.get(opts, :indices, []), &cast_index/1),
      recursors: Keyword.get(opts, :recursors, [])
    }
  end

  @spec parameter(t(), atom(), Term.t()) :: t()
  def parameter(%__MODULE__{parameters: parameters} = spec, name, type) when is_atom(name) do
    parameters = parameters ++ [%Parameter{name: name, type: type}]
    %__MODULE__{spec | parameters: parameters, num_params: length(parameters)}
  end

  @spec index(t(), atom(), Term.t()) :: t()
  def index(%__MODULE__{indices: indices} = spec, name, type) when is_atom(name) do
    %__MODULE__{spec | indices: indices ++ [%Index{name: name, type: type}]}
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

  defp cast_index(%Index{} = index), do: index
  defp cast_index({name, type}) when is_atom(name), do: %Index{name: name, type: type}
  defp cast_index(other), do: other
end
