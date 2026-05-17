defmodule Theoria.Equation.Info do
  @moduledoc "Lean-inspired metadata for a compiled equation definition."

  alias Theoria.Equation.FixedParams
  alias Theoria.Term

  @enforce_keys [:name, :type, :value]
  defstruct [
    :name,
    :type,
    :value,
    level_params: [],
    rec_arg_pos: nil,
    decl_names: [],
    fixed_params: FixedParams.new()
  ]

  @type t :: %__MODULE__{
          name: atom(),
          type: Term.t(),
          value: Term.t(),
          level_params: [atom()],
          rec_arg_pos: non_neg_integer() | nil,
          decl_names: [atom()],
          fixed_params: FixedParams.t()
        }

  @doc "Builds equation metadata for a compiled definition."
  @spec new(atom(), Term.t(), Term.t(), keyword()) :: t()
  def new(name, type, value, opts \\ []) when is_atom(name) do
    %__MODULE__{
      name: name,
      type: type,
      value: value,
      level_params: Keyword.get(opts, :level_params, []),
      rec_arg_pos: Keyword.get(opts, :rec_arg_pos),
      decl_names: Keyword.get(opts, :decl_names, [name]),
      fixed_params: Keyword.get(opts, :fixed_params, FixedParams.new())
    }
  end
end
