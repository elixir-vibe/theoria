defmodule Theoria.Equation.MatcherSpec do
  @moduledoc "Experimental/internal API for 0.1; subject to change before 0.2. Checked declaration package for a generated matcher."

  alias Theoria.Env.Matcher, as: EnvMatcher
  alias Theoria.Equation.Info
  alias Theoria.Equation.MatcherDescriptor
  alias Theoria.Equation.MatcherEqns
  alias Theoria.Equation.MatcherInfo
  alias Theoria.Equation.MatcherType
  alias Theoria.Equation.Schema
  alias Theoria.Term

  @type mode :: :source_aligned | :matcher

  @enforce_keys [:name, :source, :type, :value, :info]
  defstruct [
    :name,
    :source,
    :type,
    :value,
    :info,
    mode: :source_aligned,
    level_params: [],
    equation_names: []
  ]

  @type t :: %__MODULE__{
          name: atom(),
          source: atom(),
          type: Term.t(),
          value: Term.t(),
          info: MatcherInfo.t(),
          mode: mode(),
          level_params: [atom()],
          equation_names: [atom()]
        }

  @doc "Builds a checked matcher declaration spec from equation metadata."
  @spec from_info(Info.t(), keyword()) :: {:ok, t()} | {:error, term()}
  def from_info(info, opts \\ [])
  def from_info(%Info{matcher: nil}, _opts), do: {:error, :missing_matcher_info}

  def from_info(%Info{} = info, opts) do
    mode = Keyword.get(opts, :mode, default_mode(info))

    with {:ok, descriptor} <- descriptor_for(info, mode, Keyword.get(opts, :env)),
         {:ok, type} <- type_for(info.matcher, info.schema, info.type, mode, descriptor),
         {:ok, value} <- value_for(info.matcher, info.schema, info.value, mode, descriptor) do
      {:ok,
       %__MODULE__{
         name: info.matcher.name,
         source: info.name,
         type: type,
         value: value,
         info: info.matcher,
         mode: mode,
         level_params: info.level_params,
         equation_names: info |> MatcherEqns.generated() |> Enum.map(& &1.name)
       }}
    end
  end

  @doc "Returns the matcher type for supported equation fragments."
  @spec type_for(MatcherInfo.t(), Schema.t() | nil, Term.t(), mode()) ::
          {:ok, Term.t()} | {:error, term()}
  def type_for(%MatcherInfo{}, _schema, source_type, :source_aligned), do: {:ok, source_type}

  def type_for(%MatcherInfo{} = info, %Schema{} = schema, _source_type, :matcher),
    do: MatcherType.build(schema, info)

  @doc "Returns the matcher value for supported equation fragments."
  @spec value_for(MatcherInfo.t(), Schema.t() | nil, Term.t(), mode()) ::
          {:ok, Term.t()} | {:error, term()}
  def value_for(%MatcherInfo{}, _schema, source_value, :source_aligned), do: {:ok, source_value}

  def value_for(%MatcherInfo{} = info, %Schema{} = schema, _source_value, :matcher),
    do: MatcherType.value(schema, info)

  @doc "Converts the matcher spec to environment metadata."
  @spec metadata(t()) :: EnvMatcher.t()
  def metadata(%__MODULE__{} = spec) do
    EnvMatcher.new(spec.name, spec.source, spec.type, spec.info,
      value: spec.value,
      mode: spec.mode,
      level_params: spec.level_params,
      equation_names: spec.equation_names
    )
  end

  defp descriptor_for(_info, :source_aligned, _env), do: {:ok, nil}

  defp descriptor_for(%Info{} = info, :matcher, nil) do
    MatcherDescriptor.from_schema(info.schema, info.matcher)
  end

  defp descriptor_for(%Info{} = info, :matcher, env) do
    MatcherDescriptor.from_env(env, info.schema, info.matcher)
  end

  defp type_for(%MatcherInfo{}, _schema, source_type, :source_aligned, _descriptor),
    do: {:ok, source_type}

  defp type_for(
         %MatcherInfo{},
         %Schema{},
         _source_type,
         :matcher,
         %MatcherDescriptor{} = descriptor
       ),
       do: MatcherType.from_descriptor(descriptor)

  defp value_for(%MatcherInfo{}, _schema, source_value, :source_aligned, _descriptor),
    do: {:ok, source_value}

  defp value_for(
         %MatcherInfo{},
         %Schema{},
         _source_value,
         :matcher,
         %MatcherDescriptor{} = descriptor
       ),
       do: MatcherType.value_from_descriptor(descriptor)

  defp default_mode(%Info{schema: %Schema{family: :bool}}), do: :matcher

  defp default_mode(%Info{schema: %Schema{family: family}}) when family in [:nat, :list],
    do: :matcher

  defp default_mode(%Info{}), do: :source_aligned
end
