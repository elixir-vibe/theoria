defmodule Theoria.Kernel.Reference do
  @moduledoc "Slow, explicit reference checker for the first Theoria kernel fragment."

  alias Theoria.Context
  alias Theoria.Env
  alias Theoria.Error
  alias Theoria.Kernel.Reference.Normalize
  alias Theoria.Level
  alias Theoria.Term
  alias Theoria.Term.{App, BVar, Const, Eq, EqRec, Forall, Lam, Let, Refl, Sort}

  @type result :: {:ok, Term.t()} | {:error, Error.t()}

  @doc "Reference type inference for the supported core fragment."
  @spec infer(Env.t(), Term.t()) :: result()
  def infer(%Env{} = env, term), do: infer(env, Context.new(), term)

  @spec infer(Env.t(), Context.t(), Term.t()) :: result()
  def infer(%Env{}, %Context{}, %Sort{level: level}) do
    {:ok, Term.sort(Level.succ(level))}
  end

  def infer(%Env{}, %Context{} = context, %BVar{index: index}) do
    case Context.fetch(context, index) do
      {:ok, {_name, type}} -> {:ok, type}
      :error -> error(:unbound_variable, index: index, context_size: Context.size(context))
    end
  end

  def infer(%Env{} = env, %Context{}, %Const{name: name, levels: levels}) do
    with {:ok, constant} <- fetch_constant(env, name),
         :ok <- ensure_universe_arity(constant.universe_params, levels) do
      {:ok, Term.subst_levels(constant.type, Map.new(Enum.zip(constant.universe_params, levels)))}
    end
  end

  def infer(%Env{} = env, %Context{} = context, %App{fun: fun, arg: arg}) do
    with {:ok, fun_type} <- infer(env, context, fun),
         {:ok, fun_type} <- Normalize.whnf(env, fun_type) do
      infer_application(env, context, fun_type, arg)
    end
  end

  def infer(%Env{} = env, %Context{} = context, %Lam{name: name, domain: domain, body: body}) do
    with {:ok, %Sort{}} <- infer_sort(env, context, domain),
         body_context = Context.push(context, name, domain),
         {:ok, body_type} <- infer(env, body_context, body) do
      {:ok, Term.forall(name, domain, body_type)}
    end
  end

  def infer(%Env{} = env, %Context{} = context, %Forall{name: name, domain: domain, body: body}) do
    case infer_sort(env, context, domain) do
      {:ok, %Sort{level: domain_level}} ->
        body_context = Context.push(context, name, domain)

        case infer_sort(env, body_context, body) do
          {:ok, %Sort{level: body_level}} -> {:ok, forall_sort(domain_level, body_level)}
          {:error, _reason} = error -> error
        end

      {:error, _reason} = error ->
        error
    end
  end

  def infer(%Env{} = env, %Context{} = context, %Let{
        name: name,
        type: type,
        value: value,
        body: body
      }) do
    case infer_sort(env, context, type) do
      {:ok, %Sort{}} -> infer_checked_let(env, context, name, type, value, body)
      {:error, _reason} = error -> error
    end
  end

  def infer(%Env{} = env, %Context{} = context, %Eq{type: type, left: left, right: right}) do
    with {:ok, %Sort{}} <- infer_sort(env, context, type),
         :ok <- check(env, context, left, type),
         :ok <- check(env, context, right, type) do
      {:ok, Term.sort(0)}
    end
  end

  def infer(%Env{} = env, %Context{} = context, %Refl{value: value}) do
    with {:ok, type} <- infer(env, context, value) do
      {:ok, Term.eq(type, value, value)}
    end
  end

  def infer(%Env{} = env, %Context{} = context, %EqRec{} = eq_rec) do
    infer_eq_rec(env, context, eq_rec)
  end

  def infer(%Env{}, %Context{}, term), do: error(:unsupported_reference_term, term: term)

  defp infer_checked_let(env, context, name, type, value, body) do
    case check(env, context, value, type) do
      :ok ->
        body_type = infer(env, Context.push(context, name, type), body)
        substitute_let_type(body_type, value)

      {:error, _reason} = error ->
        error
    end
  end

  defp substitute_let_type({:ok, body_type}, value), do: {:ok, Term.subst_top(body_type, value)}
  defp substitute_let_type({:error, _reason} = error, _value), do: error

  defp infer_eq_rec(env, context, %EqRec{type: type, motive: motive, base: base, proof: proof}) do
    with {:ok, %Sort{}} <- infer_sort(env, context, type),
         {:ok, %Eq{type: proof_type, left: left, right: right}} <-
           infer_equality_proof(env, context, proof),
         :ok <- ensure_defeq(env, proof_type, type, :equality_type_mismatch),
         left_target = Term.app(motive, left),
         right_target = Term.app(motive, right),
         {:ok, %Sort{}} <- infer_sort(env, context, left_target),
         {:ok, %Sort{}} <- infer_sort(env, context, right_target),
         :ok <- check(env, context, base, left_target) do
      {:ok, right_target}
    end
  end

  defp infer_application(env, context, %Forall{domain: domain, body: body}, arg) do
    with :ok <- check(env, context, arg, domain) do
      {:ok, Term.subst_top(body, arg)}
    end
  end

  defp infer_application(_env, _context, other, _arg), do: error(:not_a_function, type: other)

  @doc "Core term constructors not covered by the reference checker."
  @spec unsupported_terms() :: [module()]
  def unsupported_terms, do: []

  @doc "Reference type checking for the supported core fragment."
  @spec check(Env.t(), Term.t(), Term.t()) :: :ok | {:error, Error.t()}
  def check(%Env{} = env, term, expected), do: check(env, Context.new(), term, expected)

  @spec check(Env.t(), Context.t(), Term.t(), Term.t()) :: :ok | {:error, Error.t()}
  def check(%Env{} = env, %Context{} = context, %Lam{} = lam, expected) do
    case Normalize.whnf(env, expected) do
      {:ok, expected} -> check_lambda(env, context, lam, expected)
      {:error, _reason} = error -> error
    end
  end

  def check(%Env{} = env, %Context{} = context, term, expected) do
    case infer(env, context, term) do
      {:ok, actual} -> ensure_defeq(env, actual, expected, :type_mismatch)
      {:error, _reason} = error -> error
    end
  end

  defp check_lambda(env, context, %Lam{} = lam, %Forall{} = expected) do
    with :ok <- ensure_defeq(env, lam.domain, expected.domain, :lambda_domain_mismatch) do
      env
      |> check(Context.push(context, lam.name, expected.domain), lam.body, expected.body)
    end
  end

  defp check_lambda(env, context, lam, expected) do
    case infer(env, context, lam) do
      {:ok, actual} -> ensure_defeq(env, actual, expected, :type_mismatch)
      {:error, _reason} = error -> error
    end
  end

  defp infer_equality_proof(env, context, proof) do
    case infer(env, context, proof) do
      {:ok, proof_type} -> normalize_equality(proof_type, env)
      {:error, _reason} = error -> error
    end
  end

  defp normalize_equality(proof_type, env) do
    case Normalize.whnf(env, proof_type) do
      {:ok, %Eq{} = equality} -> {:ok, equality}
      {:ok, other} -> error(:expected_equality, type: other)
      {:error, _reason} = error -> error
    end
  end

  defp infer_sort(env, context, term) do
    case infer(env, context, term) do
      {:ok, type} -> normalize_sort(env, type)
      {:error, _reason} = error -> error
    end
  end

  defp normalize_sort(env, type) do
    case Normalize.whnf(env, type) do
      {:ok, %Sort{} = sort} -> {:ok, sort}
      {:ok, other} -> error(:expected_sort, type: other)
      {:error, _reason} = error -> error
    end
  end

  defp fetch_constant(env, name) do
    case Env.fetch(env, name) do
      {:ok, constant} -> {:ok, constant}
      :error -> error(:unknown_constant, name: name)
    end
  end

  defp ensure_universe_arity(params, levels) do
    expected = length(params)
    actual = length(levels)

    if expected == actual, do: :ok, else: universe_arity_error(expected, actual, params)
  end

  defp universe_arity_error(expected, actual, params) do
    error(:universe_arity_mismatch, expected: expected, actual: actual, params: params)
  end

  defp ensure_defeq(env, left, right, reason) do
    if Normalize.defeq?(env, left, right) do
      :ok
    else
      error(reason, left: left, right: right)
    end
  end

  defp forall_sort(domain_level, body_level) do
    if Level.zero?(body_level) do
      Term.sort(Level.zero())
    else
      Term.sort(Level.max(domain_level, body_level))
    end
  end

  defp error(reason, details), do: {:error, %Error{reason: reason, details: details}}
end
