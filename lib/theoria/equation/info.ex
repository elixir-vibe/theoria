defmodule Theoria.Equation.Info do
  @moduledoc "Lean-inspired metadata for a compiled equation definition."

  alias Theoria.Env
  alias Theoria.Env.Constant
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

  @doc "Fetches stored equation metadata for an environment declaration."
  @spec get(Env.t(), atom()) :: {:ok, t()} | {:error, term()}
  def get(%Env{} = env, name) when is_atom(name) do
    case Env.fetch(env, name) do
      {:ok, %Constant{metadata: %__MODULE__{} = metadata}} -> {:ok, metadata}
      {:ok, %Constant{}} -> {:error, :not_equation_definition}
      :error -> {:error, {:unknown_declaration, name}}
    end
  end

  @doc "Builds equation metadata from a checked environment definition or theorem."
  @spec from_env(Env.t(), atom(), keyword()) :: {:ok, t()} | {:error, term()}
  def from_env(%Env{} = env, name, opts \\ []) when is_atom(name) do
    case Env.fetch(env, name) do
      {:ok, %Constant{value: nil}} ->
        {:error, {:missing_value, name}}

      {:ok, %Constant{} = constant} ->
        {:ok,
         new(name, constant.type, constant.value,
           level_params: constant.universe_params,
           rec_arg_pos: Keyword.get(opts, :rec_arg_pos),
           decl_names: Keyword.get(opts, :decl_names, [name]),
           fixed_params: Keyword.get(opts, :fixed_params, FixedParams.new())
         )}

      :error ->
        {:error, {:unknown_declaration, name}}
    end
  end
end
