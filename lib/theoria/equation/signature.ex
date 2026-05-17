defmodule Theoria.Equation.Signature do
  @moduledoc "Telescope summary for compiler-owned equation metadata generation."

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
    fixed_params: FixedParams.new()
  ]

  @type t :: %__MODULE__{
          name: atom(),
          family: atom(),
          parameters: [binder()],
          arguments: [binder()],
          result_type: Term.t(),
          rec_arg_pos: non_neg_integer(),
          fixed_params: FixedParams.t()
        }

  @doc "Builds a definition signature for equation metadata generation."
  @spec new(atom(), atom(), [binder()], Term.t(), keyword()) :: t()
  def new(name, family, arguments, result_type, opts \\ [])
      when is_atom(name) and is_atom(family) and is_list(arguments) do
    %__MODULE__{
      name: name,
      family: family,
      arguments: arguments,
      result_type: result_type,
      rec_arg_pos: Keyword.fetch!(opts, :rec_arg_pos),
      parameters: Keyword.get(opts, :parameters, []),
      fixed_params: Keyword.get(opts, :fixed_params, FixedParams.new())
    }
  end
end
