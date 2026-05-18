defmodule Theoria.Equation.Matcher.Equation do
  @moduledoc "Experimental/internal API for 0.2; subject to change before 0.3. Metadata for an equation generated for a matcher alternative."

  alias Theoria.Equation.Lemma
  alias Theoria.Term

  @enforce_keys [:matcher, :name, :constructor, :left, :right, :equality_type]
  defstruct [
    :matcher,
    :name,
    :constructor,
    :left,
    :right,
    :equality_type,
    binders: [],
    source: nil,
    indexed?: false,
    index_patterns: [],
    statement_type: nil,
    proof: nil,
    realizable?: true
  ]

  @type t :: %__MODULE__{
          matcher: atom(),
          name: atom(),
          constructor: atom(),
          left: Term.t(),
          right: Term.t(),
          equality_type: Term.t(),
          binders: [Lemma.binder()],
          source: Lemma.t() | nil,
          indexed?: boolean(),
          index_patterns: [Term.t()],
          statement_type: Term.t() | nil,
          proof: Term.t() | nil,
          realizable?: boolean()
        }

  @doc "Builds matcher-equation metadata from an ordinary equation lemma."
  @spec from_lemma(atom(), atom(), Lemma.t()) :: t()
  def from_lemma(matcher, constructor, %Lemma{} = lemma) when is_atom(matcher) do
    %__MODULE__{
      matcher: matcher,
      name: :"#{matcher}.eq_#{suffix_name(constructor)}",
      constructor: constructor,
      left: lemma.left,
      right: lemma.right,
      equality_type: lemma.equality_type,
      binders: lemma.binders,
      source: lemma
    }
  end

  @doc "Builds indexed matcher-equation metadata from a matcher alternative."
  @spec indexed(atom(), atom(), [Term.t()]) :: t()
  def indexed(matcher, constructor, index_patterns) when is_atom(matcher) do
    %__MODULE__{
      matcher: matcher,
      name: :"#{matcher}.eq_#{suffix_name(constructor)}",
      constructor: constructor,
      left: Term.const(matcher),
      right: Term.const(constructor),
      equality_type: Term.const(:unsupported_indexed_matcher_equation),
      indexed?: true,
      index_patterns: index_patterns,
      realizable?: false
    }
  end

  @doc "Converts matcher-equation metadata to theorem-like equation lemma metadata."
  @spec to_lemma(t()) :: Lemma.t()
  def to_lemma(%__MODULE__{} = equation) do
    Lemma.new(equation.name, equation.left, equation.right,
      binders: equation.binders,
      equality_type: equation.equality_type,
      source: equation.source && equation.source.source
    )
  end

  defp suffix_name(nil), do: "nil"
  defp suffix_name(suffix), do: Atom.to_string(suffix)
end
