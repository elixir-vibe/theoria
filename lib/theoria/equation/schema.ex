defmodule Theoria.Equation.Schema do
  @moduledoc "Schema metadata for generating equation lemmas from compiled definitions."

  alias Theoria.Term

  defmodule Equation do
    @moduledoc "One schematic equation theorem generated for a compiled definition."

    @enforce_keys [:suffix, :left, :right, :equality_type]
    defstruct [:suffix, :left, :right, :equality_type, binders: []]

    @type binder :: {atom(), Term.t()}
    @type t :: %__MODULE__{
            suffix: atom(),
            left: Term.t(),
            right: Term.t(),
            equality_type: Term.t(),
            binders: [binder()]
          }
  end

  @enforce_keys [:family, :equations]
  defstruct [
    :family,
    :recursive_argument,
    parameter_binders: [],
    argument_binders: [],
    equations: []
  ]

  @type t :: %__MODULE__{
          family: atom(),
          recursive_argument: non_neg_integer() | nil,
          parameter_binders: [Equation.binder()],
          argument_binders: [Equation.binder()],
          equations: [Equation.t()]
        }

  @doc "Builds equation generation schema metadata."
  @spec new(atom(), [Equation.t()], keyword()) :: t()
  def new(family, equations, opts \\ []) when is_atom(family) and is_list(equations) do
    %__MODULE__{
      family: family,
      equations: equations,
      recursive_argument: Keyword.get(opts, :recursive_argument),
      parameter_binders: Keyword.get(opts, :parameter_binders, []),
      argument_binders: Keyword.get(opts, :argument_binders, [])
    }
  end

  @doc "Builds one schematic equation entry."
  @spec equation(atom(), Term.t(), Term.t(), Term.t(), keyword()) :: Equation.t()
  def equation(suffix, left, right, equality_type, opts \\ []) when is_atom(suffix) do
    %Equation{
      suffix: suffix,
      left: left,
      right: right,
      equality_type: equality_type,
      binders: Keyword.get(opts, :binders, [])
    }
  end
end
