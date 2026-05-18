defmodule Theoria.Equality.Chain do
  @moduledoc "Builds kernel-checked equality artifacts for rewrite/simp traces."

  alias Theoria.Env
  alias Theoria.Equality
  alias Theoria.Equation.Identity
  alias Theoria.Equation.Realized
  alias Theoria.Kernel
  alias Theoria.Term

  @enforce_keys [:type, :start, :current]
  defstruct [:type, :start, :current, steps: []]

  @type step :: %{after: Term.t(), proof: Term.t() | nil}

  @type t :: %__MODULE__{
          type: Term.t(),
          start: Term.t(),
          current: Term.t(),
          steps: [step()]
        }

  @doc "Starts an equality chain at a term of the given type."
  @spec new(Term.t(), Term.t()) :: t()
  def new(type, start), do: %__MODULE__{type: type, start: start, current: start, steps: []}

  @doc "Appends one equality step to the chain."
  @spec step(t(), Term.t(), Term.t() | nil) :: t()
  def step(%__MODULE__{} = chain, next, proof \\ nil) do
    %{chain | current: next, steps: [%{after: next, proof: proof} | chain.steps]}
  end

  @doc "Realizes the chain as a checked equality artifact."
  @spec realize(Env.t(), t(), Identity.t()) :: {:ok, Realized.t()} | {:error, term()}
  def realize(%Env{} = env, %__MODULE__{} = chain, %Identity{} = identity) do
    theorem_type = Term.eq(chain.type, chain.start, chain.current)
    proof = proof_term(chain)

    with :ok <- Kernel.check(env, proof, theorem_type) do
      Realized.check(env, identity, theorem_type, proof)
    end
  end

  defp proof_term(%__MODULE__{start: start, steps: []}), do: Term.refl(start)

  defp proof_term(%__MODULE__{} = chain) do
    chain.steps
    |> Enum.reverse()
    |> Enum.reduce({chain.start, nil}, fn %{after: next, proof: proof}, {current, acc} ->
      cond do
        is_nil(proof) ->
          {next, nil}

        is_nil(acc) ->
          {next, proof}

        true ->
          {next, Equality.trans(chain.type, chain.start, current, next, acc, proof)}
      end
    end)
    |> elem(1)
    |> case do
      nil -> Term.refl(chain.start)
      proof -> proof
    end
  end
end
