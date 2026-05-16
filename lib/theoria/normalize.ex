defmodule Theoria.Normalize do
  @moduledoc "Normalization and definitional equality for core terms."

  alias Theoria.Env
  alias Theoria.Normalize.Primitive
  alias Theoria.Term
  alias Theoria.Term.{App, Const, Eq, Forall, Lam, Refl}

  @type result :: {:ok, Term.t()} | {:error, Theoria.Error.t()}

  def normalize(env, term) do
    with {:ok, term} <- whnf(env, term) do
      normalize_children(env, term)
    end
  end

  def whnf(env, %App{} = app) do
    with {:ok, fun} <- whnf(env, app.fun) do
      app = %App{app | fun: fun}

      case fun do
        %Lam{body: body} -> whnf(env, Term.subst_top(body, app.arg))
        _ -> Primitive.reduce(env, app, &whnf/2)
      end
    end
  end

  def whnf(%Env{} = env, %Const{name: name} = const) do
    case Env.fetch(env, name) do
      {:ok, %{value: nil}} -> {:ok, const}
      {:ok, %{value: value}} -> whnf(env, value)
      :error -> {:ok, const}
    end
  end

  def whnf(_env, term), do: {:ok, term}

  def defeq?(env, left, right) do
    with {:ok, left} <- normalize(env, left),
         {:ok, right} <- normalize(env, right) do
      left == right
    else
      _ -> false
    end
  end

  defp normalize_children(env, %App{fun: fun, arg: arg}) do
    with {:ok, fun} <- normalize(env, fun),
         {:ok, arg} <- normalize(env, arg) do
      {:ok, %App{fun: fun, arg: arg}}
    end
  end

  defp normalize_children(env, %Eq{type: type, left: left, right: right}) do
    with {:ok, type} <- normalize(env, type),
         {:ok, left} <- normalize(env, left),
         {:ok, right} <- normalize(env, right) do
      {:ok, %Eq{type: type, left: left, right: right}}
    end
  end

  defp normalize_children(env, %Refl{value: value}) do
    with {:ok, value} <- normalize(env, value) do
      {:ok, %Refl{value: value}}
    end
  end

  defp normalize_children(env, %Lam{name: name, domain: domain, body: body}) do
    with {:ok, domain} <- normalize(env, domain),
         {:ok, body} <- normalize(env, body) do
      {:ok, %Lam{name: name, domain: domain, body: body}}
    end
  end

  defp normalize_children(env, %Forall{name: name, domain: domain, body: body}) do
    with {:ok, domain} <- normalize(env, domain),
         {:ok, body} <- normalize(env, body) do
      {:ok, %Forall{name: name, domain: domain, body: body}}
    end
  end

  defp normalize_children(_env, term), do: {:ok, term}
end
