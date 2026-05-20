defmodule Theoria.Spec do
  @moduledoc """
  Elixir-facing specification vocabulary for tool-generated claims.

  `Theoria.Spec` modules are small data/checking helpers for facts produced by
  Reach, ex_ast, Vibe, and similar tools. They are not part of the trusted kernel
  by themselves; selected validated facts can become `Theoria.Obligation`s and
  checked certificates.
  """

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
end
