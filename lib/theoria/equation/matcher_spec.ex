defmodule Theoria.Equation.MatcherSpec do
  @moduledoc "Checked declaration package for a generated matcher."

  alias Theoria.Env.Matcher, as: EnvMatcher
  alias Theoria.Equation.Info
  alias Theoria.Equation.MatcherEqns
  alias Theoria.Equation.MatcherInfo
  alias Theoria.Term

  @enforce_keys [:name, :source, :type, :value, :info]
  defstruct [:name, :source, :type, :value, :info, level_params: [], equation_names: []]

  @type t :: %__MODULE__{
          name: atom(),
          source: atom(),
          type: Term.t(),
          value: Term.t(),
          info: MatcherInfo.t(),
          level_params: [atom()],
          equation_names: [atom()]
        }

  @doc "Builds a checked matcher declaration spec from equation metadata."
  @spec from_info(Info.t()) :: {:ok, t()} | {:error, term()}
  def from_info(%Info{matcher: nil}), do: {:error, :missing_matcher_info}

  def from_info(%Info{} = info) do
    {:ok,
     %__MODULE__{
       name: info.matcher.name,
       source: info.name,
       type: type_for(info.matcher, info.schema, info.type),
       value: value_for(info.matcher, info.value),
       info: info.matcher,
       level_params: info.level_params,
       equation_names: info |> MatcherEqns.generated() |> Enum.map(& &1.name)
     }}
  end

  @doc "Returns the current matcher type for supported equation fragments."
  @spec type_for(MatcherInfo.t(), Theoria.Equation.Schema.t() | nil, Term.t()) :: Term.t()
  def type_for(%MatcherInfo{}, _schema, source_type), do: source_type

  @doc "Returns the current matcher value for supported equation fragments."
  @spec value_for(MatcherInfo.t(), Term.t()) :: Term.t()
  def value_for(%MatcherInfo{}, source_value), do: source_value

  @doc "Converts the matcher spec to environment metadata."
  @spec metadata(t()) :: EnvMatcher.t()
  def metadata(%__MODULE__{} = spec) do
    EnvMatcher.new(spec.name, spec.source, spec.type, spec.info,
      value: spec.value,
      level_params: spec.level_params,
      equation_names: spec.equation_names
    )
  end
end
