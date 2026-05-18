defmodule Theoria.Equation.Schema do
  @moduledoc "Experimental/internal API for 0.1; subject to change before 0.2. Schema metadata for generating equation lemmas from compiled definitions."

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

  @doc "Validates equation schema metadata before it drives theorem generation."
  @spec validate(t()) :: :ok | {:error, term()}
  def validate(%__MODULE__{} = schema) do
    with :ok <- validate_family(schema.family),
         :ok <- validate_recursive_argument(schema),
         :ok <- validate_unique_suffixes(schema.equations) do
      validate_equations(schema.equations)
    end
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

  defp validate_family(family) when family in [:bool, :nat, :list], do: :ok
  defp validate_family(family), do: {:error, {:unsupported_family, family}}

  defp validate_recursive_argument(%__MODULE__{recursive_argument: nil}), do: :ok

  defp validate_recursive_argument(%__MODULE__{} = schema)
       when is_integer(schema.recursive_argument) and schema.recursive_argument >= 0 and
              schema.recursive_argument <
                length(schema.parameter_binders) + length(schema.argument_binders),
       do: :ok

  defp validate_recursive_argument(%__MODULE__{recursive_argument: position}),
    do: {:error, {:invalid_recursive_argument, position}}

  defp validate_unique_suffixes(equations) do
    suffixes = Enum.map(equations, & &1.suffix)

    if Enum.uniq(suffixes) == suffixes do
      :ok
    else
      {:error, :duplicate_equation_suffix}
    end
  end

  defp validate_equations(equations) do
    Enum.reduce_while(equations, :ok, fn equation, :ok ->
      case validate_equation(equation) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, {equation.suffix, reason}}}
      end
    end)
  end

  defp validate_equation(%Equation{} = equation) do
    binder_count = length(equation.binders)

    cond do
      not Term.well_scoped?(equation.equality_type, binder_count) ->
        {:error, :invalid_equality_type_scope}

      not Term.well_scoped?(equation.left, binder_count) ->
        {:error, :invalid_left_scope}

      not Term.well_scoped?(equation.right, binder_count) ->
        {:error, :invalid_right_scope}

      true ->
        :ok
    end
  end
end
