defmodule DownstreamEquations do
  @moduledoc "Small downstream module that exercises Theoria's public equation facade."

  alias Theoria.Equation
  alias Theoria.Equation.Identity
  alias Theoria.Prelude

  def check do
    with {:ok, env} <- Prelude.env(),
         summary <- Equation.summary(env),
         true <- Equation.Summary.theorems(summary) > 0,
         {:ok, identities} <- Equation.identities(env, :nat_add),
         true <- Identity.equation(:nat_add, :succ) in identities,
         {:ok, unfold} <- Equation.unfold_identity(env, :nat_add),
         true <- unfold == Identity.unfold(:nat_add),
         {:ok, theorem} <- Equation.realize(env, Identity.equation(:nat_add, :succ)) do
      {:ok, theorem.name}
    else
      false -> {:error, :unexpected_equation_facade_result}
      error -> error
    end
  end
end
