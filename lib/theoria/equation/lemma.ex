defmodule Theoria.Equation.Lemma do
  @moduledoc "Metadata for an equation lemma generated from compiled equations."

  alias Theoria.Equation.Clause
  alias Theoria.Term
  alias Theoria.Validation.DefeqCheck

  @enforce_keys [:name, :left, :right]
  defstruct [:name, :left, :right, :source]

  @type t :: %__MODULE__{
          name: atom(),
          left: Term.t(),
          right: Term.t(),
          source: Clause.t() | nil
        }

  @doc "Builds equation-lemma metadata."
  @spec new(atom(), Term.t(), Term.t(), keyword()) :: t()
  def new(name, left, right, opts \\ []) when is_atom(name) do
    %__MODULE__{name: name, left: left, right: right, source: Keyword.get(opts, :source)}
  end

  @doc "Turns equation-lemma metadata into a native definitional-equality validation check."
  @spec defeq_check(t(), atom()) :: DefeqCheck.t()
  def defeq_check(%__MODULE__{} = lemma, category) when is_atom(category) do
    DefeqCheck.new(category, Atom.to_string(lemma.name), lemma.left, lemma.right)
  end
end
