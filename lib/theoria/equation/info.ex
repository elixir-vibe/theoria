defmodule Theoria.Equation.Info do
  @moduledoc "Experimental before 1.0; the shape may change. Lean-inspired metadata for a compiled equation definition."

  alias Theoria.Env
  alias Theoria.Env.Constant
  alias Theoria.Equation.{Clause, FixedParams, Schema}
  alias Theoria.Equation.Matcher.Info, as: MatcherInfo
  alias Theoria.Term

  @enforce_keys [:name, :type, :value]
  defstruct [
    :name,
    :type,
    :value,
    level_params: [],
    rec_arg_pos: nil,
    decl_names: [],
    fixed_params: FixedParams.new(),
    clauses: [],
    matcher: nil,
    schema: nil
  ]

  @type t :: %__MODULE__{
          name: atom(),
          type: Term.t(),
          value: Term.t(),
          level_params: [atom()],
          rec_arg_pos: non_neg_integer() | nil,
          decl_names: [atom()],
          fixed_params: FixedParams.t(),
          clauses: [Clause.t()],
          matcher: MatcherInfo.t() | nil,
          schema: Schema.t() | nil
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
      fixed_params: Keyword.get(opts, :fixed_params, FixedParams.new()),
      clauses: Keyword.get(opts, :clauses, []),
      matcher: Keyword.get(opts, :matcher),
      schema: Keyword.get(opts, :schema)
    }
  end

  @doc "Fetches stored equation metadata for an environment declaration."
  @spec fetch(Env.t(), atom()) :: {:ok, t()} | {:error, term()}
  def fetch(%Env{} = env, name) when is_atom(name) do
    case Env.fetch(env, name) do
      {:ok, %Constant{metadata: %__MODULE__{} = metadata}} -> {:ok, metadata}
      {:ok, %Constant{}} -> {:error, :not_equation_definition}
      :error -> {:error, {:unknown_declaration, name}}
    end
  end

  @doc "Formats a compact metadata summary."
  @spec summary(t()) :: String.t()
  def summary(%__MODULE__{} = equation) do
    suffix =
      if equation.level_params == [] do
        ""
      else
        " levels=#{inspect(equation.level_params)}"
      end

    "#{equation.name} rec_arg=#{inspect(equation.rec_arg_pos)} fixed=#{inspect(equation.fixed_params.positions)}#{suffix}"
  end

  @doc "Returns whether an environment declaration has stored equation metadata."
  @spec equation?(Env.t(), atom()) :: boolean()
  def equation?(%Env{} = env, name), do: match?({:ok, %__MODULE__{}}, fetch(env, name))

  @doc "Fetches stored equation metadata or builds it from a valued declaration."
  @spec fetch_or_build(Env.t(), atom(), keyword()) :: {:ok, t()} | {:error, term()}
  def fetch_or_build(%Env{} = env, name, opts \\ []) when is_atom(name) do
    case fetch(env, name) do
      {:ok, %__MODULE__{} = metadata} -> {:ok, metadata}
      {:error, :not_equation_definition} -> from_env(env, name, opts)
      {:error, _reason} = error -> error
    end
  end

  @doc "Returns all stored equation metadata in declaration order."
  @spec all(Env.t()) :: [t()]
  def all(%Env{} = env) do
    env
    |> Env.declarations()
    |> Enum.filter(&is_atom/1)
    |> Enum.flat_map(&fetch_metadata(env, &1))
  end

  defp fetch_metadata(env, name) do
    case fetch(env, name) do
      {:ok, metadata} -> [metadata]
      {:error, _reason} -> []
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
           fixed_params: Keyword.get(opts, :fixed_params, FixedParams.new()),
           clauses: Keyword.get(opts, :clauses, []),
           matcher: Keyword.get(opts, :matcher),
           schema: Keyword.get(opts, :schema)
         )}

      :error ->
        {:error, {:unknown_declaration, name}}
    end
  end
end
