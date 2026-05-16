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
    fuel = fuel(opts)

    with {:ok, term, fuel} <- do_whnf(env, term, fuel),
         {:ok, term, _fuel} <- normalize_children(env, term, fuel) do
      {:ok, term}
    end
  end

  def whnf(env, term, opts \\ []) do
    with {:ok, term, _fuel} <- do_whnf(env, term, fuel(opts)) do
      {:ok, term}
    end
  end

  def defeq?(env, left, right, opts \\ []) do
    fuel = fuel(opts)

    with {:ok, left, fuel} <- do_normalize(env, left, fuel),
         {:ok, right, _fuel} <- do_normalize(env, right, fuel) do
      left == right
    else
      _ -> false
    end
  end

  defp do_normalize(env, term, fuel) do
    with {:ok, term, fuel} <- do_whnf(env, term, fuel) do
      normalize_children(env, term, fuel)
    end
  end

  defp do_whnf(env, term, fuel) do
    with {:ok, fuel} <- spend(fuel) do
      do_whnf_step(env, term, fuel)
    end
  end

  defp do_whnf_step(env, %App{} = app, fuel) do
    with {:ok, fun, fuel} <- do_whnf(env, app.fun, fuel) do
      reduce_whnf_app(env, %App{app | fun: fun}, fuel)
    end
  end

  defp do_whnf_step(%Env{} = env, %Const{name: name} = const, fuel) do
    case Env.fetch(env, name) do
      {:ok, %{value: nil}} -> {:ok, const, fuel}
      {:ok, %{value: value}} -> do_whnf(env, value, fuel)
      :error -> {:ok, const, fuel}
    end
  end

  defp do_whnf_step(_env, term, fuel), do: {:ok, term, fuel}

  defp reduce_whnf_app(env, %App{fun: %Lam{body: body}, arg: arg}, fuel) do
    do_whnf(env, Term.subst_top(body, arg), fuel)
  end

  defp reduce_whnf_app(env, %App{} = app, fuel) do
    case Primitive.reduce(env, app, fn env, term -> do_whnf(env, term, fuel) end) do
      {:stuck, app} -> {:ok, app, fuel}
      other -> other
    end
  end

  defp normalize_children(env, %App{fun: fun, arg: arg}, fuel) do
    with {:ok, fun, fuel} <- do_normalize(env, fun, fuel),
         {:ok, arg, fuel} <- do_normalize(env, arg, fuel) do
      {:ok, %App{fun: fun, arg: arg}, fuel}
    end
  end

  defp normalize_children(env, %Eq{type: type, left: left, right: right}, fuel) do
    with {:ok, type, fuel} <- do_normalize(env, type, fuel),
         {:ok, left, fuel} <- do_normalize(env, left, fuel),
         {:ok, right, fuel} <- do_normalize(env, right, fuel) do
      {:ok, %Eq{type: type, left: left, right: right}, fuel}
    end
  end

  defp normalize_children(env, %Refl{value: value}, fuel) do
    with {:ok, value, fuel} <- do_normalize(env, value, fuel) do
      {:ok, %Refl{value: value}, fuel}
    end
  end

  defp normalize_children(env, %Lam{name: name, domain: domain, body: body}, fuel) do
    with {:ok, domain, fuel} <- do_normalize(env, domain, fuel),
         {:ok, body, fuel} <- do_normalize(env, body, fuel) do
      {:ok, %Lam{name: name, domain: domain, body: body}, fuel}
    end
  end

  defp normalize_children(env, %Forall{name: name, domain: domain, body: body}, fuel) do
    with {:ok, domain, fuel} <- do_normalize(env, domain, fuel),
         {:ok, body, fuel} <- do_normalize(env, body, fuel) do
      {:ok, %Forall{name: name, domain: domain, body: body}, fuel}
    end
  end

  defp normalize_children(_env, term, fuel), do: {:ok, term, fuel}

  defp fuel(opts) do
    max_steps = Keyword.get(opts, :max_steps, @default_max_steps)
    %{remaining_steps: max_steps, max_steps: max_steps}
  end

  defp spend(%{remaining_steps: remaining_steps, max_steps: max_steps})
       when remaining_steps <= 0 do
    error(:normalization_limit, max_steps: max_steps)
  end

  defp spend(%{remaining_steps: remaining_steps} = fuel) do
    {:ok, %{fuel | remaining_steps: remaining_steps - 1}}
  end

  defp error(reason, details), do: {:error, %Error{reason: reason, details: details}}
end
