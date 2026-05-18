defmodule Theoria.Env.Matcher do
  @moduledoc "Environment metadata for a generated matcher declaration."

  alias Theoria.Equation.Matcher.Info, as: MatcherInfo
  alias Theoria.Term

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
          mode: :source_aligned | :matcher | :indexed_matcher,
          level_params: [atom()],
          equation_names: [atom()]
        }

  @doc "Builds matcher declaration metadata from a source equation definition."
  @spec new(atom(), atom(), Term.t(), MatcherInfo.t(), keyword()) :: t()
  def new(name, source, type, %MatcherInfo{} = info, opts \\ [])
      when is_atom(name) and is_atom(source) do
    %__MODULE__{
      name: name,
      source: source,
      type: type,
      value: Keyword.fetch!(opts, :value),
      info: info,
      mode: Keyword.get(opts, :mode, :source_aligned),
      level_params: Keyword.get(opts, :level_params, []),
      equation_names: Keyword.get(opts, :equation_names, [])
    }
  end
end
