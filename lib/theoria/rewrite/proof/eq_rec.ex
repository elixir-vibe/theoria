defmodule Theoria.Rewrite.Proof.EqRec do
  @moduledoc """
  Experimental EqRec-path proof lifting helpers.

  The shape may change before 1.0.
  """

  alias Theoria.Env
  alias Theoria.Kernel
  alias Theoria.Rewrite.Proof.Capabilities
  alias Theoria.Rewrite.Proof.Capability
  alias Theoria.Rewrite.Proof.Check
  alias Theoria.Rewrite.Step
  alias Theoria.Term

  @spec explain(Step.t()) :: Capability.t()
  def explain(%Step{path: [:proof]}), do: Capabilities.explain([:proof])
  def explain(%Step{path: [:base]}), do: Capabilities.explain([:base])
  def explain(%Step{path: path}), do: Capabilities.explain(path)

  @spec lift_base(Env.t(), Term.t(), Term.t(), Step.t()) :: {:ok, Term.t()} | {:error, atom()}
  def lift_base(%Env{} = env, result_type, proof, %Step{} = step) do
    case {step.before, step.after} do
      {%Term.EqRec{} = before, %Term.EqRec{} = after_term}
      when before.type == after_term.type and before.motive == after_term.motive and
             before.proof == after_term.proof ->
        with {:ok, base_type} <- Kernel.infer(env, before.base) do
          target = %Term.EqRec{
            before
            | type: Term.shift(before.type, 1),
              motive: Term.shift(before.motive, 1),
              base: Term.bvar(0),
              proof: Term.shift(before.proof, 1)
          }

          motive =
            Term.lam(
              :z,
              base_type,
              Term.eq(Term.shift(result_type, 1), Term.shift(step.before, 1), target)
            )

          check_lifted(
            env,
            result_type,
            Term.eq_rec(base_type, motive, Term.refl(step.before), proof),
            step
          )
        end

      _ ->
        {:error, :unsupported_path}
    end
  end

  @spec lift_proof(Env.t(), Term.t(), Term.t(), Step.t()) :: {:ok, Term.t()} | {:error, atom()}
  def lift_proof(%Env{} = env, result_type, proof, %Step{} = step) do
    case {step.before, step.after} do
      {%Term.EqRec{} = before, %Term.EqRec{} = after_term}
      when before.type == after_term.type and before.motive == after_term.motive and
             before.base == after_term.base ->
        with {:ok, proof_type} <- Kernel.infer(env, before.proof) do
          target = %Term.EqRec{
            before
            | type: Term.shift(before.type, 1),
              motive: Term.shift(before.motive, 1),
              base: Term.shift(before.base, 1),
              proof: Term.bvar(0)
          }

          motive =
            Term.lam(
              :h,
              proof_type,
              Term.eq(Term.shift(result_type, 1), Term.shift(step.before, 1), target)
            )

          check_lifted(
            env,
            result_type,
            Term.eq_rec(proof_type, motive, Term.refl(step.before), proof),
            step
          )
        end

      _ ->
        {:error, :unsupported_path}
    end
  end

  defp check_lifted(env, type, candidate, step), do: Check.lifted(env, type, candidate, step)
end
