defmodule Theoria.Obligation do
  @moduledoc """
  Tool-generated proof obligation checked by the native kernel.

  Obligations are the post-0.8 bridge between Elixir tooling and Theoria's
  trusted kernel. A tool records a claim kind, optional assumptions/witness data,
  the Theoria goal term, and an optional proof term. `check/2` only returns a
  checked certificate when `Theoria.Kernel.check/3` accepts the proof against the
  goal.

      iex> goal = Theoria.Term.eq(Theoria.Term.sort(1), Theoria.Term.sort(0), Theoria.Term.sort(0))
      iex> proof = Theoria.Term.refl(Theoria.Term.sort(0))
      iex> obligation = Theoria.Obligation.new(:sort_refl, goal, proof: proof)
      iex> {:ok, cert} = Theoria.Obligation.check(Theoria.new_env(), obligation)
      iex> Theoria.Certificate.checked?(cert)
      true
  """

  alias Theoria.Certificate
  alias Theoria.Env
  alias Theoria.Kernel
  alias Theoria.Term

  @type source :: %{optional(atom()) => term()}

  @type t :: %__MODULE__{
          id: term(),
          kind: atom(),
          goal: Term.t(),
          proof: Term.t() | nil,
          assumptions: [term()],
          witness: term(),
          source: source(),
          metadata: map()
        }

  @enforce_keys [:kind, :goal]
  defstruct [:id, :kind, :goal, :proof, :witness, assumptions: [], source: %{}, metadata: %{}]

  @doc "Builds a proof obligation."
  @spec new(atom(), Term.t(), keyword()) :: t()
  def new(kind, goal, opts \\ []) when is_atom(kind) do
    %__MODULE__{
      id: Keyword.get(opts, :id),
      kind: kind,
      goal: goal,
      proof: Keyword.get(opts, :proof),
      assumptions: Keyword.get(opts, :assumptions, []),
      witness: Keyword.get(opts, :witness),
      source: Map.new(Keyword.get(opts, :source, %{})),
      metadata: Map.new(Keyword.get(opts, :metadata, %{}))
    }
  end

  @doc "Returns the obligation kind."
  @spec kind(t()) :: atom()
  def kind(%__MODULE__{kind: kind}), do: kind

  @doc "Returns the optional obligation id."
  @spec id(t()) :: term()
  def id(%__MODULE__{id: id}), do: id

  @doc "Returns the goal term that must be proven."
  @spec goal(t()) :: Term.t()
  def goal(%__MODULE__{goal: goal}), do: goal

  @doc "Returns the optional proof term."
  @spec proof(t()) :: Term.t() | nil
  def proof(%__MODULE__{proof: proof}), do: proof

  @doc "Returns the assumption metadata carried by the producing tool."
  @spec assumptions(t()) :: [term()]
  def assumptions(%__MODULE__{assumptions: assumptions}), do: assumptions

  @doc "Returns the optional witness carried by the producing tool."
  @spec witness(t()) :: term()
  def witness(%__MODULE__{witness: witness}), do: witness

  @doc "Returns producer/source metadata such as tool name, version, or input hashes."
  @spec source(t()) :: source()
  def source(%__MODULE__{source: source}), do: source

  @doc "Returns additional metadata for diagnostics and reports."
  @spec metadata(t()) :: map()
  def metadata(%__MODULE__{metadata: metadata}), do: metadata

  @doc "Checks an obligation and returns a replayable certificate."
  @spec check(Env.t(), t()) :: {:ok, Certificate.t()} | {:error, Certificate.t()}
  def check(%Env{}, %__MODULE__{proof: nil} = obligation) do
    {:error, Certificate.unchecked(obligation, :missing_proof)}
  end

  def check(%Env{} = env, %__MODULE__{} = obligation) do
    case Kernel.check(env, obligation.proof, obligation.goal) do
      :ok -> {:ok, Certificate.checked(obligation)}
      {:error, reason} -> {:error, Certificate.failed(obligation, reason)}
    end
  end
end
