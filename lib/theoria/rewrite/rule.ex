defmodule Theoria.Rewrite.Rule do
  @moduledoc "Experimental/internal API for 0.2; subject to change before 0.3. A theorem-like rewrite rule over a core equality term."

  alias Theoria.Equation.Lemma
  alias Theoria.Equation.Name
  alias Theoria.Term

  @enforce_keys [:name, :equality]
  defstruct [:name, :equality, :id, direction: :forward, binders: []]

  @type t :: %__MODULE__{
          name: atom() | Name.t(),
          equality: Term.Eq.t(),
          id: Name.t() | nil,
          direction: :forward | :backward,
          binders: [Lemma.binder()]
        }

  @doc "Builds a rewrite rule."
  @spec new(atom() | Name.t(), Term.Eq.t(), keyword()) :: t()
  def new(name_or_id, equality, opts \\ [])

  def new(%Name{} = id, %Term.Eq{} = equality, opts) do
    new_with_name(id, equality, Keyword.put(opts, :id, id))
  end

  def new(name, %Term.Eq{} = equality, opts) when is_atom(name) do
    new_with_name(name, equality, opts)
  end

  defp new_with_name(name, %Term.Eq{} = equality, opts) do
    %__MODULE__{
      name: name,
      equality: equality,
      id: Keyword.get(opts, :id),
      direction: Keyword.get(opts, :direction, :forward),
      binders: Keyword.get(opts, :binders, [])
    }
  end

  @doc "Builds a rewrite rule from equation-lemma metadata."
  @spec from_lemma(Lemma.t(), Term.t() | keyword(), keyword()) :: t()
  def from_lemma(%Lemma{} = lemma, equality_or_opts \\ [], opts \\ []) do
    {equality_type, opts} = equality_type_and_opts(lemma, equality_or_opts, opts)

    new(lemma.id || lemma.name, Term.eq(equality_type, lemma.left, lemma.right),
      binders: lemma.binders,
      direction: Keyword.get(opts, :direction, :forward)
    )
  end

  defp equality_type_and_opts(%Lemma{} = lemma, opts, []) when is_list(opts) do
    {lemma.equality_type || Keyword.fetch!(opts, :equality_type), opts}
  end

  defp equality_type_and_opts(_lemma, equality_type, opts), do: {equality_type, opts}
end
