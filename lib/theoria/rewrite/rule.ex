defmodule Theoria.Rewrite.Rule do
  @moduledoc "Experimental/internal API for 0.2; subject to change before 0.3. A theorem-like rewrite rule over a core equality term."

  alias Theoria.Env
  alias Theoria.Equation.Identity
  alias Theoria.Equation.Lemma
  alias Theoria.Equation.Realized
  alias Theoria.Term

  @enforce_keys [:name, :equality]
  defstruct [:name, :equality, :identity, :proof, :realized, direction: :forward, binders: []]

  @type t :: %__MODULE__{
          name: atom() | Identity.t(),
          equality: Term.Eq.t(),
          identity: Identity.t() | nil,
          proof: Term.t() | nil,
          realized: Theoria.Equation.Realized.t() | nil,
          direction: :forward | :backward,
          binders: [Lemma.binder()]
        }

  @doc "Builds a rewrite rule."
  @spec new(atom() | Identity.t(), Term.Eq.t(), keyword()) :: t()
  def new(name_or_id, equality, opts \\ [])

  def new(%Identity{} = identity, %Term.Eq{} = equality, opts) do
    new_with_name(identity, equality, Keyword.put(opts, :identity, identity))
  end

  def new(name, %Term.Eq{} = equality, opts) when is_atom(name) do
    new_with_name(name, equality, opts)
  end

  defp new_with_name(name, %Term.Eq{} = equality, opts) do
    %__MODULE__{
      name: name,
      equality: equality,
      identity: Keyword.get(opts, :identity),
      proof: Keyword.get(opts, :proof),
      realized: Keyword.get(opts, :realized),
      direction: Keyword.get(opts, :direction, :forward),
      binders: Keyword.get(opts, :binders, [])
    }
  end

  @doc "Builds a rewrite rule from a realized equation artifact."
  @spec from_realized(Realized.t()) :: t()
  def from_realized(%Realized{identity: identity, type: %Term.Eq{} = equality} = realized) do
    new(identity, equality, proof: realized.proof, realized: realized)
  end

  @doc "Builds a rewrite rule from equation-lemma metadata, realizing it first when requested."
  @spec from_realizing_lemma(Env.t(), Lemma.t(), keyword()) :: t()
  def from_realizing_lemma(%Env{} = env, %Lemma{} = lemma, opts \\ []) do
    if Keyword.get(opts, :realize, false) do
      case Lemma.realize(env, lemma, opts) do
        {:ok, realized} ->
          from_lemma(lemma, Keyword.merge(opts, proof: realized.proof, realized: realized))

        {:error, _reason} ->
          from_lemma(lemma, opts)
      end
    else
      from_lemma(lemma, opts)
    end
  end

  @doc "Builds a rewrite rule from equation-lemma metadata."
  @spec from_lemma(Lemma.t(), Term.t() | keyword(), keyword()) :: t()
  def from_lemma(%Lemma{} = lemma, equality_or_opts \\ [], opts \\ []) do
    {equality_type, opts} = equality_type_and_opts(lemma, equality_or_opts, opts)

    new(lemma.identity || lemma.name, Term.eq(equality_type, lemma.left, lemma.right),
      binders: lemma.binders,
      direction: Keyword.get(opts, :direction, :forward),
      proof: Keyword.get(opts, :proof),
      realized: Keyword.get(opts, :realized)
    )
  end

  defp equality_type_and_opts(%Lemma{} = lemma, opts, []) when is_list(opts) do
    {lemma.equality_type || Keyword.fetch!(opts, :equality_type), opts}
  end

  defp equality_type_and_opts(_lemma, equality_type, opts), do: {equality_type, opts}
end
