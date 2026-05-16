defmodule Theoria.Normalize do
  @moduledoc "Normalization and definitional equality for core terms."

  alias Theoria.Env
  alias Theoria.Env.Constant
  alias Theoria.Normalize.Fuel
  alias Theoria.Normalize.Primitive
  alias Theoria.Term
  alias Theoria.Term.{App, Const, Eq, Forall, Lam, Let, Refl, Sort}

  @type result :: {:ok, Term.t()} | {:error, Theoria.Error.t()}

  def normalize(env, term, opts \\ []) do
    fuel = Fuel.new(opts)

    with {:ok, term, fuel} <- do_whnf(env, term, fuel),
         {:ok, term, _fuel} <- normalize_children(env, term, fuel) do
      {:ok, term}
    end
  end

  def whnf(env, term, opts \\ []) do
    with {:ok, term, _fuel} <- do_whnf(env, term, Fuel.new(opts)) do
      {:ok, term}
    end
  end

  def defeq?(env, left, right, opts \\ []) do
    fuel = Fuel.new(opts)

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
    with {:ok, fuel} <- Fuel.spend(fuel) do
      do_whnf_step(env, term, fuel)
    end
  end

  defp do_whnf_step(env, %App{} = app, fuel) do
    with {:ok, fun, fuel} <- do_whnf(env, app.fun, fuel) do
      reduce_whnf_app(env, %App{app | fun: fun}, fuel)
    end
  end

  defp do_whnf_step(env, %Let{value: value, body: body}, fuel) do
    do_whnf(env, Term.subst_top(body, value), fuel)
  end

  defp do_whnf_step(%Env{} = env, %Const{name: name} = const, fuel) do
    case Env.fetch(env, name) do
      {:ok, %Constant{value: value, reducible?: true, universe_params: params}} ->
        value = Term.subst_levels(value, Enum.zip(params, const.levels) |> Map.new())
        do_whnf(env, value, fuel)

      {:ok, _constant} ->
        {:ok, const, fuel}

      :error ->
        {:ok, const, fuel}
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

  defp normalize_children(env, %Let{type: type, value: value, body: body, name: name}, fuel) do
    with {:ok, type, fuel} <- do_normalize(env, type, fuel),
         {:ok, value, fuel} <- do_normalize(env, value, fuel),
         {:ok, body, fuel} <- do_normalize(env, body, fuel) do
      {:ok, %Let{name: name, type: type, value: value, body: body}, fuel}
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

  defp normalize_children(_env, %Sort{level: level}, fuel) do
    {:ok, %Sort{level: Theoria.Level.normalize(level)}, fuel}
  end

  defp normalize_children(_env, %Const{levels: levels} = term, fuel) do
    {:ok, %Const{term | levels: Enum.map(levels, &Theoria.Level.normalize/1)}, fuel}
  end

  defp normalize_children(_env, term, fuel), do: {:ok, term, fuel}
end
