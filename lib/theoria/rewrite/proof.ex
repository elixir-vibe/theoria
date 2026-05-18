defmodule Theoria.Rewrite.Proof do
  @moduledoc "Proof construction helpers for structural rewrite steps."

  alias Theoria.Env
  alias Theoria.Equality
  alias Theoria.Kernel
  alias Theoria.Rewrite.Match
  alias Theoria.Rewrite.Rule
  alias Theoria.Rewrite.Step
  alias Theoria.Term

  @doc "Instantiates a realized or proof-backed rule proof with the rewrite substitution."
  @spec instantiate_rule(Rule.t(), Match.substitution() | nil) :: Term.t() | nil
  def instantiate_rule(%Rule{proof: nil}, _substitution), do: nil
  def instantiate_rule(%Rule{proof: proof}, nil), do: proof

  def instantiate_rule(%Rule{proof: proof, binders: binders}, substitution) do
    substitution
    |> ordered_arguments(length(binders))
    |> Enum.reduce(proof, &Term.app(&2, &1))
  end

  @doc "Returns a checked proof for a rewrite step when currently supported."
  @spec for_step(Env.t(), Step.t()) :: Term.t() | nil
  def for_step(%Env{} = env, %Step{} = step) do
    with {:ok, type} <- Kernel.infer(env, step.before),
         proof when not is_nil(proof) <- local_or_defeq_proof(env, type, step),
         :ok <- Kernel.check(env, proof, Term.eq(type, step.before, step.after)) do
      proof
    else
      _ -> nil
    end
  end

  defp local_or_defeq_proof(env, type, %Step{proof: proof, path: []} = step)
       when not is_nil(proof) do
    if Kernel.check(env, proof, Term.eq(type, step.before, step.after)) == :ok do
      proof
    else
      defeq_proof(env, type, step.before, step.after)
    end
  end

  defp local_or_defeq_proof(env, type, %Step{proof: proof, path: [:arg]} = step)
       when not is_nil(proof) do
    case step.before do
      %Term.App{fun: fun, arg: left} ->
        case step.after do
          %Term.App{fun: ^fun, arg: right} ->
            lift_app_arg_or_defeq(env, type, fun, left, right, proof, step)

          _ ->
            defeq_proof(env, type, step.before, step.after)
        end

      _ ->
        defeq_proof(env, type, step.before, step.after)
    end
  end

  defp local_or_defeq_proof(env, type, %Step{} = step),
    do: defeq_proof(env, type, step.before, step.after)

  defp lift_app_arg_or_defeq(env, type, fun, left, right, proof, step) do
    with {:ok, domain} <- Kernel.infer(env, left),
         candidate = Equality.congr(domain, type, fun, left, right, proof),
         :ok <- Kernel.check(env, candidate, Term.eq(type, step.before, step.after)) do
      candidate
    else
      _ -> defeq_proof(env, type, step.before, step.after)
    end
  end

  defp defeq_proof(env, type, before, after_term) do
    proof = Term.refl(before)

    case Kernel.check(env, proof, Term.eq(type, before, after_term)) do
      :ok -> proof
      {:error, _reason} -> nil
    end
  end

  defp ordered_arguments(_substitution, 0), do: []

  defp ordered_arguments(substitution, count) do
    0..(count - 1)//1
    |> Enum.map(&Map.fetch!(substitution, &1))
    |> Enum.reverse()
  end
end
