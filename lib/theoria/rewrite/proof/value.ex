defmodule Theoria.Rewrite.Proof.Value do
  @moduledoc false

  alias Theoria.Env
  alias Theoria.Kernel
  alias Theoria.Rewrite.Proof.Check
  alias Theoria.Rewrite.Step
  alias Theoria.Term

  @spec lift(Env.t(), Term.t(), Term.t(), Step.t()) :: {:ok, Term.t()} | {:error, atom()}
  def lift(%Env{} = env, result_type, proof, %Step{before: %Term.Let{}} = step),
    do: lift_let_value(env, result_type, proof, step)

  def lift(_env, _result_type, _proof, _step), do: {:error, :unsupported_path}

  defp lift_let_value(env, result_type, proof, step) do
    case {step.before, step.after} do
      {%Term.Let{} = before, %Term.Let{} = after_term}
      when before.name == after_term.name and before.type == after_term.type and
             before.body == after_term.body ->
        with {:ok, value_type} <- Kernel.infer(env, before.value) do
          target = %Term.Let{
            before
            | type: Term.shift(before.type, 1),
              value: Term.bvar(0),
              body: Term.shift(before.body, 1)
          }

          motive =
            Term.lam(
              before.name,
              value_type,
              Term.eq(Term.shift(result_type, 1), Term.shift(step.before, 1), target)
            )

          Check.lifted(
            env,
            result_type,
            Term.eq_rec(value_type, motive, Term.refl(step.before), proof),
            step
          )
        end

      _ ->
        {:error, :unsupported_path}
    end
  end
end
