defmodule Theoria.Rewrite.Proof do
  @moduledoc "Proof construction helpers for structural rewrite steps."

  alias Theoria.Env
  alias Theoria.Equality
  alias Theoria.Kernel
  alias Theoria.Rewrite.Match
  alias Theoria.Rewrite.Proof.Capabilities
  alias Theoria.Rewrite.Proof.Check
  alias Theoria.Rewrite.Proof.EqRec, as: EqRecProof
  alias Theoria.Rewrite.Proof.Result
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
    case attach(env, step) do
      %Step{proof_result: %Result{proof: proof, status: :checked}} -> proof
      %Step{} -> nil
    end
  end

  @doc "Attaches proof status and a checked proof to a rewrite step when possible."
  @spec attach(Env.t(), Step.t()) :: Step.t()
  def attach(%Env{} = env, %Step{} = step) do
    capability = Capabilities.explain(step.path)

    case proof_result(env, step) do
      {:ok, proof} -> %{step | proof_result: Result.checked(proof, capability)}
      {:error, status} -> %{step | proof_result: Result.rejected(status, capability)}
    end
  end

  defp proof_result(%Env{} = env, %Step{} = step) do
    with {:ok, type} <- Kernel.infer(env, step.before),
         {:ok, proof} <- local_or_defeq_proof(env, type, step),
         :ok <- Kernel.check(env, proof, Term.eq(type, step.before, step.after)) do
      {:ok, proof}
    else
      {:error, %Theoria.Error{}} -> {:error, :kernel_rejected}
      {:error, status} when is_atom(status) -> {:error, status}
    end
  end

  defp local_or_defeq_proof(
         env,
         type,
         %Step{proof_result: %Result{proof: proof}, path: []} = step
       )
       when not is_nil(proof) do
    if Kernel.check(env, proof, Term.eq(type, step.before, step.after)) == :ok do
      {:ok, proof}
    else
      defeq_proof(env, type, step.before, step.after)
    end
  end

  defp local_or_defeq_proof(
         env,
         type,
         %Step{proof_result: %Result{proof: proof}, path: path} = step
       )
       when not is_nil(proof) and path != [],
       do: lift_path_or_defeq(env, type, proof, step)

  defp local_or_defeq_proof(_env, _type, %Step{proof_result: nil}),
    do: {:error, :missing_rule_proof}

  defp local_or_defeq_proof(_env, _type, %Step{proof_result: %Result{proof: nil}}),
    do: {:error, :missing_rule_proof}

  defp local_or_defeq_proof(env, type, %Step{} = step) do
    case defeq_proof(env, type, step.before, step.after) do
      {:ok, _proof} = ok -> ok
      {:error, _status} -> {:error, :unsupported_path}
    end
  end

  defp lift_path_or_defeq(env, type, proof, step) do
    case lift_path(env, type, proof, step) do
      {:ok, proof} -> {:ok, proof}
      {:error, _status} -> defeq_proof(env, type, step.before, step.after)
    end
  end

  defp lift_path(env, type, proof, %Step{path: [:arg]} = step),
    do: lift_app_arg(env, type, proof, step)

  defp lift_path(env, type, proof, %Step{path: [:fun]} = step),
    do: lift_app_fun(env, type, proof, step)

  defp lift_path(env, type, proof, %Step{path: [:left]} = step),
    do: lift_eq_left(env, type, proof, step)

  defp lift_path(env, type, proof, %Step{path: [:right]} = step),
    do: lift_eq_right(env, type, proof, step)

  defp lift_path(env, type, proof, %Step{path: [:base]} = step),
    do: EqRecProof.lift_base(env, type, proof, step)

  defp lift_path(env, type, proof, %Step{path: [:proof]} = step),
    do: EqRecProof.lift_proof(env, type, proof, step)

  defp lift_path(env, type, proof, %Step{path: [:value]} = step),
    do: lift_value(env, type, proof, step)

  defp lift_path(env, type, proof, %Step{path: [:arg | rest]} = step) do
    case {step.before, step.after} do
      {%Term.App{fun: fun, arg: left}, %Term.App{fun: after_fun, arg: right}}
      when fun == after_fun ->
        nested = %Step{
          step
          | before: left,
            after: right,
            path: rest,
            proof_result: Result.checked(proof, Capabilities.explain(rest))
        }

        with {:ok, nested_type} <- Kernel.infer(env, left),
             {:ok, nested_proof} <- local_or_defeq_proof(env, nested_type, nested) do
          lift_app_arg(env, type, nested_proof, %{step | path: [:arg]})
        end

      _ ->
        {:error, :unsupported_path}
    end
  end

  defp lift_path(env, type, proof, %Step{path: [:fun | rest]} = step) do
    case {step.before, step.after} do
      {%Term.App{fun: left_fun, arg: arg}, %Term.App{fun: right_fun, arg: after_arg}}
      when arg == after_arg ->
        nested = %Step{
          step
          | before: left_fun,
            after: right_fun,
            path: rest,
            proof_result: Result.checked(proof, Capabilities.explain(rest))
        }

        with {:ok, nested_type} <- Kernel.infer(env, left_fun),
             {:ok, nested_proof} <- local_or_defeq_proof(env, nested_type, nested) do
          lift_app_fun(env, type, nested_proof, %{step | path: [:fun]})
        end

      _ ->
        {:error, :unsupported_path}
    end
  end

  defp lift_path(env, type, proof, %Step{path: [:base | rest]} = step) do
    case {step.before, step.after} do
      {%Term.EqRec{} = before, %Term.EqRec{} = after_term}
      when before.type == after_term.type and before.motive == after_term.motive and
             before.proof == after_term.proof ->
        nested = %Step{
          step
          | before: before.base,
            after: after_term.base,
            path: rest,
            proof_result: Result.checked(proof, Capabilities.explain(rest))
        }

        with {:ok, nested_type} <- Kernel.infer(env, before.base),
             {:ok, nested_proof} <- local_or_defeq_proof(env, nested_type, nested) do
          EqRecProof.lift_base(env, type, nested_proof, %{step | path: [:base]})
        end

      _ ->
        {:error, :unsupported_path}
    end
  end

  defp lift_path(env, type, proof, %Step{path: [:proof | rest]} = step) do
    case {step.before, step.after} do
      {%Term.EqRec{} = before, %Term.EqRec{} = after_term}
      when before.type == after_term.type and before.motive == after_term.motive and
             before.base == after_term.base ->
        nested = %Step{
          step
          | before: before.proof,
            after: after_term.proof,
            path: rest,
            proof_result: Result.checked(proof, Capabilities.explain(rest))
        }

        with {:ok, nested_type} <- Kernel.infer(env, before.proof),
             {:ok, nested_proof} <- local_or_defeq_proof(env, nested_type, nested) do
          EqRecProof.lift_proof(env, type, nested_proof, %{step | path: [:proof]})
        end

      _ ->
        {:error, :unsupported_path}
    end
  end

  defp lift_path(_env, _type, _proof, _step), do: {:error, :unsupported_path}

  defp lift_eq_left(env, proposition_type, proof, step) do
    case {step.before, step.after} do
      {%Term.Eq{type: value_type, left: left, right: right},
       %Term.Eq{type: after_type, left: _after_left, right: after_right}}
      when value_type == after_type and right == after_right ->
        motive =
          Term.lam(
            :z,
            value_type,
            Term.eq(
              Term.shift(proposition_type, 1),
              Term.eq(Term.shift(value_type, 1), Term.shift(left, 1), Term.shift(right, 1)),
              Term.eq(Term.shift(value_type, 1), Term.bvar(0), Term.shift(right, 1))
            )
          )

        check_lifted(
          env,
          proposition_type,
          Term.eq_rec(value_type, motive, Term.refl(step.before), proof),
          step
        )

      _ ->
        {:error, :unsupported_path}
    end
  end

  defp lift_eq_right(env, proposition_type, proof, step) do
    case {step.before, step.after} do
      {%Term.Eq{type: value_type, left: left, right: right},
       %Term.Eq{type: after_type, left: after_left, right: _after_right}}
      when value_type == after_type and left == after_left ->
        motive =
          Term.lam(
            :z,
            value_type,
            Term.eq(
              Term.shift(proposition_type, 1),
              Term.eq(Term.shift(value_type, 1), Term.shift(left, 1), Term.shift(right, 1)),
              Term.eq(Term.shift(value_type, 1), Term.shift(left, 1), Term.bvar(0))
            )
          )

        check_lifted(
          env,
          proposition_type,
          Term.eq_rec(value_type, motive, Term.refl(step.before), proof),
          step
        )

      _ ->
        {:error, :unsupported_path}
    end
  end

  defp lift_value(env, result_type, proof, %Step{before: %Term.Let{}} = step),
    do: lift_let_value(env, result_type, proof, step)

  defp lift_value(_env, _result_type, _proof, _step), do: {:error, :unsupported_path}

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

          check_lifted(
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

  defp check_lifted(env, type, candidate, step), do: Check.lifted(env, type, candidate, step)

  defp lift_app_arg(env, type, proof, step) do
    case {step.before, step.after} do
      {%Term.App{fun: fun, arg: left}, %Term.App{fun: after_fun, arg: right}}
      when fun == after_fun ->
        with {:ok, domain} <- Kernel.infer(env, left),
             candidate = Equality.congr(domain, type, fun, left, right, proof),
             :ok <- Kernel.check(env, candidate, Term.eq(type, step.before, step.after)) do
          {:ok, candidate}
        else
          _ -> defeq_proof(env, type, step.before, step.after)
        end

      _ ->
        defeq_proof(env, type, step.before, step.after)
    end
  end

  defp lift_app_fun(env, type, proof, step) do
    case {step.before, step.after} do
      {%Term.App{fun: left_fun, arg: arg}, %Term.App{fun: right_fun, arg: after_arg}}
      when arg == after_arg ->
        with {:ok, fun_type} <- Kernel.infer(env, left_fun),
             candidate = Equality.congr_fun(fun_type, type, arg, left_fun, right_fun, proof),
             :ok <- Kernel.check(env, candidate, Term.eq(type, step.before, step.after)) do
          {:ok, candidate}
        else
          _ -> defeq_proof(env, type, step.before, step.after)
        end

      _ ->
        defeq_proof(env, type, step.before, step.after)
    end
  end

  defp defeq_proof(env, type, before, after_term) do
    proof = Term.refl(before)

    case Kernel.check(env, proof, Term.eq(type, before, after_term)) do
      :ok -> {:ok, proof}
      {:error, _reason} -> {:error, :kernel_rejected}
    end
  end

  defp ordered_arguments(_substitution, 0), do: []

  defp ordered_arguments(substitution, count) do
    0..(count - 1)//1
    |> Enum.map(&Map.fetch!(substitution, &1))
    |> Enum.reverse()
  end
end
