defmodule Theoria.Spec do
  @moduledoc """
  Elixir-facing specification vocabulary for tool-generated claims.

  `Theoria.Spec` modules are small data/checking helpers for facts produced by
  Reach, ex_ast, Vibe, and similar tools. They are not part of the trusted kernel
  by themselves; selected validated facts can become `Theoria.Obligation`s and
  checked certificates.
  """

  alias Theoria.Obligation
  alias Theoria.Spec.Claim
  alias Theoria.Spec.Report

  @doc "Returns true when a structural claim is valid."
  @spec valid?(term()) :: boolean()
  def valid?(claim), do: Claim.valid?(claim)

  @doc "Returns true when every structural claim is valid."
  @spec all_valid?([term()]) :: boolean()
  def all_valid?(claims) when is_list(claims), do: Enum.all?(claims, &valid?/1)

  @doc "Builds a report for structural claims."
  @spec report([term()]) :: Report.t()
  def report(claims) when is_list(claims), do: Report.new(claims)

  @doc "Builds a kernel obligation from a valid structural claim."
  @spec obligation(term(), Theoria.Term.t(), keyword()) ::
          {:ok, Obligation.t()} | {:error, term()}
  def obligation(claim, goal, opts \\ []) do
    claim_kind = Claim.kind(claim)

    if Claim.valid?(claim) do
      kind = Keyword.get(opts, :kind, claim_kind)
      metadata = Map.put(Map.new(Keyword.get(opts, :metadata, %{})), :claim_kind, claim_kind)

      {:ok,
       Obligation.new(kind, goal,
         id: Keyword.get(opts, :id),
         proof: Keyword.get(opts, :proof),
         assumptions: Keyword.get(opts, :assumptions, []),
         witness: claim,
         source: Keyword.get(opts, :source, %{}),
         metadata: metadata
       )}
    else
      {:error, {:invalid_spec_claim, claim_kind, Claim.reason(claim)}}
    end
  end

  @doc "Builds and checks a kernel obligation from a valid structural claim."
  @spec check_claim(Theoria.Env.t(), term(), Theoria.Term.t(), keyword()) ::
          {:ok, Theoria.Certificate.t()} | {:error, term()}
  def check_claim(env, claim, goal, opts \\ []) do
    with {:ok, obligation} <- obligation(claim, goal, opts) do
      Obligation.check(env, obligation)
    end
  end
end
