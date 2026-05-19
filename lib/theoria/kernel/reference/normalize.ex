defmodule Theoria.Kernel.Reference.Normalize do
  @moduledoc "Reference normalization for kernel differential assurance."

  alias Theoria.Env
  alias Theoria.Env.Constant
  alias Theoria.Kernel.Reference.Primitive
  alias Theoria.Term
  alias Theoria.Term.{App, Const, Eq, EqRec, Forall, Lam, Let, Refl, Sort}

  @fuel 1_000

  @type result :: {:ok, Term.t()} | {:error, :out_of_fuel}

  @doc "Computes weak-head normal form with the reference normalizer."
  @spec whnf(Env.t(), Term.t()) :: result()
  def whnf(%Env{} = env, term) do
    case whnf_loop(env, term, @fuel) do
      {:ok, term, _fuel} -> {:ok, term}
      {:error, _reason} = error -> error
    end
  end

  @doc "Computes full normal form with the reference normalizer."
  @spec normalize(Env.t(), Term.t()) :: result()
  def normalize(%Env{} = env, term) do
    case whnf_loop(env, term, @fuel) do
      {:ok, term, fuel} -> normalize_children(env, term, fuel)
      {:error, _reason} = error -> error
    end
  end

  @doc "Reference definitional equality by full normalization."
  @spec defeq?(Env.t(), Term.t(), Term.t()) :: boolean()
  def defeq?(%Env{} = env, left, right) do
    case {normalize(env, left), normalize(env, right)} do
      {{:ok, left}, {:ok, right}} -> left == right
      _other -> false
    end
  end

  defp whnf_loop(_env, _term, 0), do: {:error, :out_of_fuel}

  defp whnf_loop(env, term, fuel) do
    fuel = fuel - 1

    case term do
      %App{} = app -> whnf_app(env, app, fuel)
      %Let{} = let -> whnf_loop(env, Term.subst_top(let.body, let.value), fuel)
      %EqRec{} = eq_rec -> whnf_eq_rec(env, eq_rec, fuel)
      %Const{} = const -> whnf_const(env, const, fuel)
      other -> {:ok, other, fuel}
    end
  end

  defp whnf_app(env, %App{} = app, fuel) do
    case whnf_loop(env, app.fun, fuel) do
      {:ok, %Lam{body: body}, fuel} -> whnf_loop(env, Term.subst_top(body, app.arg), fuel)
      {:ok, fun, fuel} -> reduce_primitive_app(env, %App{app | fun: fun}, fuel)
      {:error, _reason} = error -> error
    end
  end

  defp reduce_primitive_app(env, app, fuel) do
    case Primitive.reduce(
           env,
           app,
           fn env, term -> whnf_loop(env, term, fuel) end,
           &defeq?/3
         ) do
      {:stuck, app} -> {:ok, app, fuel}
      {:ok, term, fuel} -> {:ok, term, fuel}
      {:error, _reason} = error -> error
    end
  end

  defp whnf_eq_rec(env, %EqRec{} = eq_rec, fuel) do
    case whnf_loop(env, eq_rec.proof, fuel) do
      {:ok, %Refl{}, fuel} -> whnf_loop(env, eq_rec.base, fuel)
      {:ok, proof, fuel} -> {:ok, %EqRec{eq_rec | proof: proof}, fuel}
      {:error, _reason} = error -> error
    end
  end

  defp whnf_const(env, %Const{} = const, fuel) do
    case Env.fetch(env, const.name) do
      {:ok, %Constant{value: value, reducible?: true, universe_params: params}} ->
        instantiated = Term.subst_levels(value, Map.new(Enum.zip(params, const.levels)))
        whnf_loop(env, instantiated, fuel)

      _other ->
        {:ok, const, fuel}
    end
  end

  defp normalize_children(env, term, fuel) do
    case normalize_child_terms(env, term, fuel) do
      {:ok, term, _fuel} -> {:ok, term}
      {:error, _reason} = error -> error
    end
  end

  defp normalize_child_terms(env, %App{} = term, fuel) do
    with {:ok, fun, fuel} <- normalize_term(env, term.fun, fuel),
         {:ok, arg, fuel} <- normalize_term(env, term.arg, fuel) do
      {:ok, %App{fun: fun, arg: arg}, fuel}
    end
  end

  defp normalize_child_terms(env, %Let{} = term, fuel) do
    with {:ok, type, fuel} <- normalize_term(env, term.type, fuel),
         {:ok, value, fuel} <- normalize_term(env, term.value, fuel),
         {:ok, body, fuel} <- normalize_term(env, term.body, fuel) do
      {:ok, %Let{term | type: type, value: value, body: body}, fuel}
    end
  end

  defp normalize_child_terms(env, %Eq{} = term, fuel) do
    with {:ok, type, fuel} <- normalize_term(env, term.type, fuel),
         {:ok, left, fuel} <- normalize_term(env, term.left, fuel),
         {:ok, right, fuel} <- normalize_term(env, term.right, fuel) do
      {:ok, %Eq{type: type, left: left, right: right}, fuel}
    end
  end

  defp normalize_child_terms(env, %Refl{} = term, fuel) do
    with {:ok, value, fuel} <- normalize_term(env, term.value, fuel) do
      {:ok, %Refl{value: value}, fuel}
    end
  end

  defp normalize_child_terms(env, %EqRec{} = term, fuel) do
    with {:ok, type, fuel} <- normalize_term(env, term.type, fuel),
         {:ok, motive, fuel} <- normalize_term(env, term.motive, fuel),
         {:ok, base, fuel} <- normalize_term(env, term.base, fuel),
         {:ok, proof, fuel} <- normalize_term(env, term.proof, fuel) do
      {:ok, %EqRec{type: type, motive: motive, base: base, proof: proof}, fuel}
    end
  end

  defp normalize_child_terms(env, %Lam{} = term, fuel) do
    with {:ok, domain, fuel} <- normalize_term(env, term.domain, fuel),
         {:ok, body, fuel} <- normalize_term(env, term.body, fuel) do
      {:ok, %Lam{term | domain: domain, body: body}, fuel}
    end
  end

  defp normalize_child_terms(env, %Forall{} = term, fuel) do
    with {:ok, domain, fuel} <- normalize_term(env, term.domain, fuel),
         {:ok, body, fuel} <- normalize_term(env, term.body, fuel) do
      {:ok, %Forall{term | domain: domain, body: body}, fuel}
    end
  end

  defp normalize_child_terms(_env, %Sort{} = term, fuel) do
    {:ok, %Sort{term | level: Theoria.Level.normalize(term.level)}, fuel}
  end

  defp normalize_child_terms(_env, %Const{} = term, fuel) do
    {:ok, %Const{term | levels: Enum.map(term.levels, &Theoria.Level.normalize/1)}, fuel}
  end

  defp normalize_child_terms(_env, term, fuel), do: {:ok, term, fuel}

  defp normalize_term(env, term, fuel) do
    case whnf_loop(env, term, fuel) do
      {:ok, term, fuel} -> normalize_child_terms(env, term, fuel)
      {:error, _reason} = error -> error
    end
  end
end
