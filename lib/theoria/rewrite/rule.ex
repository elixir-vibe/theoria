defmodule Theoria.Rewrite.Rule do
  @moduledoc "Experimental/internal API for 0.2; subject to change before 0.3. A theorem-like rewrite rule over a core equality term."

  alias Theoria.Equation.Lemma
  alias Theoria.Term

  @enforce_keys [:name, :equality]
  defstruct [:name, :equality, direction: :forward, binders: []]

  @type t :: %__MODULE__{
          name: atom(),
          equality: Term.Eq.t(),
          direction: :forward | :backward,
          binders: [Lemma.binder()]
        }

  @doc "Builds a rewrite rule."
  @spec new(atom(), Term.Eq.t(), keyword()) :: t()
  def new(name, %Term.Eq{} = equality, opts \\ []) when is_atom(name) do
    %__MODULE__{
      name: name,
      equality: equality,
      direction: Keyword.get(opts, :direction, :forward),
      binders: Keyword.get(opts, :binders, [])
    }
  end

  @doc "Builds a rewrite rule from equation-lemma metadata."
  @spec from_lemma(Lemma.t(), Term.t() | keyword(), keyword()) :: t()
  def from_lemma(%Lemma{} = lemma, equality_or_opts \\ [], opts \\ []) do
    {equality_type, opts} = equality_type_and_opts(lemma, equality_or_opts, opts)

    new(lemma.name, Term.eq(equality_type, lemma.left, lemma.right),
      binders: lemma.binders,
      direction: Keyword.get(opts, :direction, :forward)
    )
  end

  defp equality_type_and_opts(%Lemma{} = lemma, opts, []) when is_list(opts) do
    {lemma.equality_type || Keyword.fetch!(opts, :equality_type), opts}
  end

  defp equality_type_and_opts(_lemma, equality_type, opts), do: {equality_type, opts}
end
