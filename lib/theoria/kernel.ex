defmodule Theoria.Kernel do
  @moduledoc """
  The trusted type-checking kernel.

  The kernel is intentionally small: all DSLs, tactics, and automation must
  reduce to core terms that are accepted here before a theorem is trusted.
  """

  alias Theoria.Context
  alias Theoria.Env
  alias Theoria.Error
  alias Theoria.Normalize
  alias Theoria.Term
  alias Theoria.Term.{App, BVar, Const, Forall, Lam, Sort}

  @type result :: {:ok, Term.t()} | {:error, Error.t()}

  def infer(env, term), do: infer(env, Context.new(), term)

  def infer(%Env{} = _env, _context, %Sort{level: level}) do
    {:ok, %Sort{level: level + 1}}
  end

  def infer(%Env{} = _env, %Context{} = context, %BVar{index: index}) do
    case Context.fetch(context, index) do
      {:ok, {_name, type}} -> {:ok, type}
      :error -> error(:unbound_variable, index: index, context_size: Context.size(context))
    end
  end

  def infer(%Env{} = env, _context, %Const{name: name}) do
    case Env.fetch(env, name) do
      {:ok, constant} -> {:ok, constant.type}
      :error -> error(:unknown_constant, name: name)
    end
  end

  def infer(%Env{} = env, %Context{} = context, %App{fun: fun, arg: arg}) do
    with {:ok, fun_type} <- infer(env, context, fun),
         {:ok, fun_type} <- Normalize.whnf(env, fun_type) do
      infer_application_type(env, context, fun_type, arg)
    end
  end

  def infer(%Env{} = env, %Context{} = context, %Lam{name: name, domain: domain, body: body}) do
    with {:ok, %Sort{}} <- infer_sort(env, context, domain),
         extended = Context.push(context, name, domain),
         {:ok, body_type} <- infer(env, extended, body) do
      {:ok, %Forall{name: name, domain: domain, body: body_type}}
    end
  end

  def infer(%Env{} = env, %Context{} = context, %Forall{name: name, domain: domain, body: body}) do
    with {:ok, %Sort{level: domain_level}} <- infer_sort(env, context, domain),
         extended = Context.push(context, name, domain),
         {:ok, %Sort{level: body_level}} <- infer_sort(env, extended, body) do
      {:ok, %Sort{level: max(domain_level, body_level)}}
    end
  end

  def check(env, term, expected), do: check(env, Context.new(), term, expected)

  def check(%Env{} = env, %Context{} = context, %Lam{} = lam, %Forall{} = expected) do
    with :ok <- ensure_defeq(env, lam.domain, expected.domain, :lambda_domain_mismatch) do
      extended = Context.push(context, lam.name, expected.domain)
      check(env, extended, lam.body, expected.body)
    end
  end

  def check(%Env{} = env, %Context{} = context, term, expected) do
    case infer(env, context, term) do
      {:ok, actual} -> ensure_defeq(env, actual, expected, :type_mismatch)
      {:error, error} -> {:error, error}
    end
  end

  def add_constant(%Env{} = env, name, type) when is_atom(name) do
    with {:ok, %Sort{}} <- infer_sort(env, Context.new(), type) do
      {:ok, Env.put_constant(env, name, type)}
    end
  end

  def add_definition(%Env{} = env, name, type, value) when is_atom(name) do
    with {:ok, %Sort{}} <- infer_sort(env, Context.new(), type),
         :ok <- check(env, Context.new(), value, type) do
      {:ok, Env.put_definition(env, name, type, value)}
    end
  end

  defp infer_application_type(env, context, %Forall{domain: domain, body: body}, arg) do
    with :ok <- check(env, context, arg, domain) do
      {:ok, Term.subst_top(body, arg)}
    end
  end

  defp infer_application_type(_env, _context, other, _arg) do
    error(:not_a_function, type: other)
  end

  defp infer_sort(env, context, term) do
    with {:ok, type} <- infer(env, context, term),
         {:ok, type} <- Normalize.whnf(env, type) do
      case type do
        %Sort{} -> {:ok, type}
        other -> error(:expected_sort, type: other)
      end
    end
  end

  defp ensure_defeq(env, left, right, reason) do
    if Normalize.defeq?(env, left, right) do
      :ok
    else
      error(reason, left: left, right: right)
    end
  end

  defp error(reason, details), do: {:error, %Error{reason: reason, details: details}}
end
