defmodule Theoria.Simp do
  @moduledoc "Experimental/internal API for 0.2; subject to change before 0.3. Tiny untrusted simplification groundwork backed by generated equation rules."

  alias Theoria.Env
  alias Theoria.Equality.Chain
  alias Theoria.Equation.Identity
  alias Theoria.Equation.Realized
  alias Theoria.Kernel
  alias Theoria.Rewrite.Proof, as: RewriteProof
  alias Theoria.Simp.Database
  alias Theoria.Simp.Result
  alias Theoria.Simp.Step
  alias Theoria.Term
  alias Theoria.Theorem

  @type result :: Result.t()

  @doc "Applies one generated equation simplification, if possible."
  @spec once(Env.t(), Term.t(), keyword()) :: {:ok, Term.t(), Step.t()} | :not_found
  def once(%Env{} = env, term, opts \\ []) do
    env
    |> database(opts)
    |> Database.once_with_step(env, term, opts)
    |> case do
      {:ok, rewrite_step, rule} -> {:ok, rewrite_step.after, step(env, rule, rewrite_step, opts)}
      :not_found -> :not_found
    end
  end

  @doc "Repeatedly applies generated equation simplifications until normal form or fuel exhaustion."
  @spec normalize(Env.t(), Term.t(), keyword()) :: result()
  def normalize(%Env{} = env, term, opts \\ []) do
    max_steps = Keyword.get(opts, :max_steps, 100)
    database = database(env, opts)

    normalize_with_database(database, env, term, term, max_steps, [], opts)
    |> maybe_attach_proof(env, opts)
  end

  @doc "Normalizes and realizes the produced equality as a checked artifact."
  @spec realize(Env.t(), Term.t(), keyword()) :: {:ok, Realized.t()} | {:error, term()}
  def realize(%Env{} = env, term, opts \\ []) do
    result = normalize(env, term, Keyword.put(opts, :prove, true))

    case result.realized do
      %Realized{} = realized -> {:ok, realized}
      nil -> {:error, :simp_realization_failed}
    end
  end

  @doc "Normalizes a term, realizes the equality proof, and installs it under a user declaration name."
  @spec add_theorem(Env.t(), atom(), Term.t(), keyword()) ::
          {:ok, Env.t(), Theorem.t()} | {:error, term()}
  def add_theorem(%Env{} = env, name, term, opts \\ []) when is_atom(name) do
    with {:ok, realized} <- realize(env, term, opts),
         theorem = %Theorem{
           name: name,
           type: realized.type,
           proof: realized.proof,
           universe_params: realized.universe_params
         },
         {:ok, env} <- Theorem.add_to_env(env, theorem) do
      {:ok, env, theorem}
    end
  end

  defp normalize_with_database(_database, _env, input, term, 0, steps, _opts) do
    %Result{input: input, term: term, steps: Enum.reverse(steps), stopped: :fuel}
  end

  defp normalize_with_database(database, env, input, term, remaining, steps, opts) do
    case Database.once_with_step(database, env, term, opts) do
      {:ok, rewrite_step, rule} ->
        normalize_with_database(
          database,
          env,
          input,
          rewrite_step.after,
          remaining - 1,
          [step(env, rule, rewrite_step, opts) | steps],
          opts
        )

      :not_found ->
        %Result{input: input, term: term, steps: Enum.reverse(steps), stopped: :normal}
    end
  end

  defp database(env, opts) do
    if Keyword.get(opts, :include_matchers, false) do
      Database.from_env_all_equations(env, opts)
    else
      Database.from_env_equations(env, opts)
    end
  end

  defp maybe_attach_proof(%Result{} = result, env, opts) do
    if Keyword.get(opts, :prove, false) do
      attach_proof(result, env, opts)
    else
      result
    end
  end

  defp attach_proof(%Result{} = result, env, opts) do
    identity = Keyword.get(opts, :identity, Identity.simp())

    with {:ok, type} <- Kernel.infer(env, result.input),
         chain = proof_chain(type, result),
         {:ok, realized} <- Chain.realize(env, chain, identity) do
      %{result | type: realized.type, proof: realized.proof, realized: realized}
    else
      {:error, _reason} -> result
    end
  end

  defp proof_chain(type, %Result{} = result) do
    Enum.reduce(result.steps, Chain.new(type, result.input), fn step, chain ->
      Chain.step(chain, step.after, proof_from_result(step.proof_result))
    end)
  end

  defp proof_from_result(%Theoria.Rewrite.Proof.Result{proof: proof}), do: proof
  defp proof_from_result(_result), do: nil

  defp step(env, rule, rewrite_step, opts) do
    proved_step = proved_step(env, rewrite_step, opts)

    %Step{
      rule: rule.rewrite.name,
      before: rewrite_step.before,
      after: rewrite_step.after,
      proof_result: proved_step.proof_result,
      path: rewrite_step.path,
      source: rule.source
    }
  end

  defp proved_step(env, rewrite_step, opts) do
    if Keyword.get(opts, :prove, false) do
      RewriteProof.attach(env, rewrite_step)
    else
      %{rewrite_step | proof_result: Theoria.Rewrite.Proof.Result.not_requested()}
    end
  end
end
