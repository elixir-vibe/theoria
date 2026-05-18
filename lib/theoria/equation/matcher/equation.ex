defmodule Theoria.Equation.Matcher.Equation do
  @moduledoc "Experimental/internal API for 0.2; subject to change before 0.3. Metadata for an equation generated for a matcher alternative."

  alias Theoria.Equation.Lemma
  alias Theoria.Equation.Name
  alias Theoria.Term

  @enforce_keys [:matcher, :name, :constructor, :left, :right, :equality_type]
  defstruct [
    :matcher,
    :id,
    :name,
    :constructor,
    :left,
    :right,
    :equality_type,
    binders: [],
    source: nil,
    indexed?: false,
    index_patterns: [],
    statement_name: nil,
    statement_type: nil,
    statement_status: :planned,
    proof: nil,
    realizable?: true
  ]

  @type t :: %__MODULE__{
          matcher: atom(),
          id: Name.t() | nil,
          name: atom() | Name.t(),
          constructor: atom(),
          left: Term.t(),
          right: Term.t(),
          equality_type: Term.t(),
          binders: [Lemma.binder()],
          source: Lemma.t() | nil,
          indexed?: boolean(),
          index_patterns: [Term.t()],
          statement_name: atom() | Name.t() | nil,
          statement_type: Term.t() | nil,
          statement_status: :planned | :realizable | :realized | :unsupported,
          proof: Term.t() | nil,
          realizable?: boolean()
        }

  @doc "Builds matcher-equation metadata from an ordinary equation lemma."
  @spec from_lemma(atom(), atom(), Lemma.t()) :: t()
  def from_lemma(matcher, constructor, %Lemma{} = lemma) when is_atom(matcher) do
    id = Name.matcher_equation(matcher, constructor)

    %__MODULE__{
      matcher: matcher,
      id: id,
      name: id,
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
    id = Name.indexed_matcher_equation(matcher, constructor)

    %__MODULE__{
      matcher: matcher,
      id: id,
      name: id,
      constructor: constructor,
      left: Term.const(matcher),
      right: Term.const(constructor),
      equality_type: Term.const(:unsupported_indexed_matcher_equation),
      indexed?: true,
      index_patterns: index_patterns,
      statement_name: id,
      statement_status: :unsupported,
      realizable?: false
    }
  end

  @doc "Converts matcher-equation metadata to theorem-like equation lemma metadata."
  @spec to_lemma(t()) :: Lemma.t()
  def to_lemma(%__MODULE__{} = equation) do
    Lemma.new(equation.id || equation.name, equation.left, equation.right,
      binders: equation.binders,
      equality_type: equation.equality_type,
      source: equation.source && equation.source.source
    )
  end
end
