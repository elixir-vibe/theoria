defmodule Theoria.Equation.Signature do
  @moduledoc "Experimental/internal API for 0.2; subject to change before 0.3. Telescope summary for compiler-owned equation metadata generation."

  alias Theoria.Equation.FixedParams
  alias Theoria.Term

  @type binder :: {atom(), Term.t()}

  @enforce_keys [:name, :family, :arguments, :result_type, :rec_arg_pos]
  defstruct [
    :name,
    :family,
    :result_type,
    :rec_arg_pos,
    parameters: [],
    arguments: [],
    fixed_params: FixedParams.new(),
    discriminant_positions: nil
  ]

  @type t :: %__MODULE__{
          name: atom(),
          family: atom(),
          parameters: [binder()],
          arguments: [binder()],
          result_type: Term.t(),
          rec_arg_pos: non_neg_integer(),
          fixed_params: FixedParams.t(),
          discriminant_positions: [non_neg_integer()] | nil
        }

  @doc "Builds a definition signature for equation metadata generation."
  @spec new(atom(), atom(), [binder()], Term.t(), keyword()) :: t()
  def new(name, family, arguments, result_type, opts \\ [])
      when is_atom(name) and is_atom(family) and is_list(arguments) do
    rec_arg_pos = Keyword.fetch!(opts, :rec_arg_pos)
    parameters = Keyword.get(opts, :parameters, [])

    signature = %__MODULE__{
      name: name,
      family: family,
      arguments: arguments,
      result_type: result_type,
      rec_arg_pos: rec_arg_pos,
      parameters: parameters,
      fixed_params: FixedParams.new(),
      discriminant_positions: Keyword.get(opts, :discriminant_positions)
    }

    %{signature | fixed_params: Keyword.get(opts, :fixed_params, derived_fixed_params(signature))}
  end

  defp derived_fixed_params(signature) do
    case FixedParams.analyze(signature) do
      {:ok, fixed_params} -> fixed_params
      {:error, _reason} -> FixedParams.new()
    end
  end
end
