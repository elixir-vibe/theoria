defmodule Theoria.Equality.Chain do
  @moduledoc "Builds kernel-checked equality artifacts for rewrite/simp traces."

  alias Theoria.Env
  alias Theoria.Equality
  alias Theoria.Equality.Chain.Result
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
    proof_result = proof_result(chain)

    with :ok <- Kernel.check(env, proof_result.proof, theorem_type),
         {:ok, realized} <- Realized.check(env, identity, theorem_type, proof_result.proof) do
      {:ok, %{realized | proof_strategy: proof_result.strategy}}
    end
  end

  @doc "Returns the proof term and strategy selected for a chain."
  @spec proof_result(t()) :: Result.t()
  def proof_result(%__MODULE__{start: start, steps: []}),
    do: %Result{proof: Term.refl(start), strategy: :refl}

  def proof_result(%__MODULE__{} = chain) do
    steps = Enum.reverse(chain.steps)

    case proof_term(chain, steps) do
      {proof, strategy} -> %Result{proof: proof, strategy: strategy}
      nil -> %Result{proof: Term.refl(chain.start), strategy: :fallback_defeq}
    end
  end

  defp proof_term(%__MODULE__{} = chain, steps) do
    steps
    |> Enum.reduce({chain.start, nil, :refl}, fn %{after: next, proof: proof},
                                                 {current, acc, strategy} ->
      cond do
        is_nil(proof) ->
          {next, nil, strategy}

        is_nil(acc) ->
          {next, proof, :single}

        true ->
          {next, Equality.trans(chain.type, chain.start, current, next, acc, proof), :transitive}
      end
    end)
    |> case do
      {_current, nil, _strategy} -> nil
      {_current, proof, strategy} -> {proof, strategy}
    end
  end
end
