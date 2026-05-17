defmodule Theoria.Equation.DefinitionSpec do
  @moduledoc "Complete metadata package for a compiled equation definition."

  alias Theoria.Env
  alias Theoria.Equation.{FixedParams, Info, MatcherInfo, Schema}
  alias Theoria.Kernel
  alias Theoria.Term

  @enforce_keys [:name, :type, :value]
  defstruct [
    :name,
    :type,
    :value,
    level_params: [],
    rec_arg_pos: nil,
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
          fixed_params: FixedParams.t(),
          clauses: [Theoria.Equation.Clause.t()],
          matcher: MatcherInfo.t() | nil,
          schema: Schema.t() | nil
        }

  @doc "Builds and validates a compiled equation definition specification."
  @spec new(atom(), Term.t(), Term.t(), keyword()) :: {:ok, t()} | {:error, term()}
  def new(name, type, value, opts \\ []) when is_atom(name) do
    spec = %__MODULE__{
      name: name,
      type: type,
      value: value,
      level_params: Keyword.get(opts, :level_params, []),
      rec_arg_pos: Keyword.get(opts, :rec_arg_pos),
      fixed_params: Keyword.get(opts, :fixed_params, FixedParams.new()),
      clauses: Keyword.get(opts, :clauses, []),
      schema: Keyword.get(opts, :schema)
    }

    spec = %{spec | matcher: Keyword.get(opts, :matcher) || matcher_for(name, spec.schema)}

    with :ok <- validate_schema(spec.schema) do
      {:ok, spec}
    end
  end

  @doc "Stores a compiled equation definition in the kernel environment."
  @spec add_to_env(Env.t(), t()) :: {:ok, Env.t()} | {:error, Theoria.Error.t()}
  def add_to_env(%Env{} = env, %__MODULE__{} = spec) do
    Kernel.add_definition(env, spec.name, spec.type, spec.value, spec.level_params,
      metadata: info(spec)
    )
  end

  @doc "Converts a definition spec to stored equation metadata."
  @spec info(t()) :: Info.t()
  def info(%__MODULE__{} = spec) do
    Info.new(spec.name, spec.type, spec.value,
      level_params: spec.level_params,
      rec_arg_pos: spec.rec_arg_pos,
      fixed_params: spec.fixed_params,
      clauses: spec.clauses,
      matcher: spec.matcher,
      schema: spec.schema
    )
  end

  defp matcher_for(_name, nil), do: nil
  defp matcher_for(name, %Schema{} = schema), do: MatcherInfo.for_schema(name, schema)

  defp validate_schema(nil), do: :ok

  defp validate_schema(%Schema{} = schema) do
    case Schema.validate(schema) do
      :ok -> :ok
      {:error, reason} -> {:error, {:invalid_schema, reason}}
    end
  end
end
