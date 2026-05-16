defmodule Theoria.Normalize do
  @moduledoc "Normalization and definitional equality for core terms."

  alias Theoria.Env
  alias Theoria.Error
  alias Theoria.Normalize.Primitive
  alias Theoria.Term
  alias Theoria.Term.{App, Const, Eq, Forall, Lam, Refl}

  @type result :: {:ok, Term.t()} | {:error, Error.t()}

  @default_max_steps 10_000

  def normalize(env, term, opts \\ []) do
    max_steps = max_steps(opts)

    with {:ok, term} <- do_whnf(env, term, max_steps, max_steps) do
      normalize_children(env, term, max_steps)
    end
  end

  def whnf(env, term, opts \\ []) do
    max_steps = max_steps(opts)
    do_whnf(env, term, max_steps, max_steps)
  end

  def defeq?(env, left, right, opts \\ []) do
    with {:ok, left} <- normalize(env, left, opts),
         {:ok, right} <- normalize(env, right, opts) do
      left == right
    else
      _ -> false
    end
  end

  defp do_whnf(_env, _term, remaining_steps, max_steps) when remaining_steps <= 0 do
    error(:normalization_limit, max_steps: max_steps)
  end

  defp do_whnf(env, %App{} = app, remaining_steps, max_steps) do
    with {:ok, fun} <- do_whnf(env, app.fun, remaining_steps - 1, max_steps) do
      reduce_whnf_app(env, %App{app | fun: fun}, remaining_steps, max_steps)
    end
  end

  defp do_whnf(%Env{} = env, %Const{name: name} = const, remaining_steps, max_steps) do
    case Env.fetch(env, name) do
      {:ok, %{value: nil}} -> {:ok, const}
      {:ok, %{value: value}} -> do_whnf(env, value, remaining_steps - 1, max_steps)
      :error -> {:ok, const}
    end
  end

  defp do_whnf(_env, term, _remaining_steps, _max_steps), do: {:ok, term}

  defp reduce_whnf_app(env, %App{fun: %Lam{body: body}, arg: arg}, remaining_steps, max_steps) do
    do_whnf(env, Term.subst_top(body, arg), remaining_steps - 1, max_steps)
  end

  defp reduce_whnf_app(env, %App{} = app, remaining_steps, max_steps) do
    Primitive.reduce(env, app, fn env, term ->
      do_whnf(env, term, remaining_steps - 1, max_steps)
    end)
  end

  defp normalize_children(env, %App{fun: fun, arg: arg}, max_steps) do
    with {:ok, fun} <- normalize(env, fun, max_steps: max_steps),
         {:ok, arg} <- normalize(env, arg, max_steps: max_steps) do
      {:ok, %App{fun: fun, arg: arg}}
    end
  end

  defp normalize_children(env, %Eq{type: type, left: left, right: right}, max_steps) do
    with {:ok, type} <- normalize(env, type, max_steps: max_steps),
         {:ok, left} <- normalize(env, left, max_steps: max_steps),
         {:ok, right} <- normalize(env, right, max_steps: max_steps) do
      {:ok, %Eq{type: type, left: left, right: right}}
    end
  end

  defp normalize_children(env, %Refl{value: value}, max_steps) do
    with {:ok, value} <- normalize(env, value, max_steps: max_steps) do
      {:ok, %Refl{value: value}}
    end
  end

  defp normalize_children(env, %Lam{name: name, domain: domain, body: body}, max_steps) do
    with {:ok, domain} <- normalize(env, domain, max_steps: max_steps),
         {:ok, body} <- normalize(env, body, max_steps: max_steps) do
      {:ok, %Lam{name: name, domain: domain, body: body}}
    end
  end

  defp normalize_children(env, %Forall{name: name, domain: domain, body: body}, max_steps) do
    with {:ok, domain} <- normalize(env, domain, max_steps: max_steps),
         {:ok, body} <- normalize(env, body, max_steps: max_steps) do
      {:ok, %Forall{name: name, domain: domain, body: body}}
    end
  end

  defp normalize_children(_env, term, _max_steps), do: {:ok, term}

  defp max_steps(opts), do: Keyword.get(opts, :max_steps, @default_max_steps)

  defp error(reason, details), do: {:error, %Error{reason: reason, details: details}}
end
