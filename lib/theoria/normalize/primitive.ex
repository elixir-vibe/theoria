defmodule Theoria.Normalize.Primitive do
  @moduledoc "Primitive weak-head reductions for declarations with reduction metadata."

  alias Theoria.Env
  alias Theoria.Env.Constant
  alias Theoria.Env.Reduction
  alias Theoria.Term
  alias Theoria.Term.{App, Const}

  @type fuel :: Theoria.Normalize.Fuel.t()
  @type whnf_result :: {:ok, Term.t(), fuel()} | {:error, Theoria.Error.t()}
  @type whnf_fun :: (Env.t(), Term.t() -> whnf_result())
  @type result :: whnf_result() | {:stuck, App.t()}

  @spec reduce(Env.t(), App.t(), whnf_fun()) :: result()
  def reduce(%Env{} = env, %App{} = app, whnf) when is_function(whnf, 2) do
    case Term.Application.collect(app) do
      {%Const{name: name}, args} -> reduce_constant(env, name, args, app, whnf)
      _other -> {:stuck, app}
    end
  end

  defp reduce_constant(env, name, args, fallback, whnf) do
    case Env.fetch(env, name) do
      {:ok, %Constant{reduction: reduction}} when not is_nil(reduction) ->
        reduce_by_metadata(env, reduction, args, fallback, whnf)

      _other ->
        {:stuck, fallback}
    end
  end

  defp reduce_by_metadata(env, %Reduction.BoolRec{}, args, fallback, whnf) do
    reduce_bool(env, args, fallback, whnf)
  end

  defp reduce_by_metadata(env, %Reduction.BoolInd{}, args, fallback, whnf) do
    reduce_bool(env, args, fallback, whnf)
  end

  defp reduce_by_metadata(env, %Reduction.NatRec{}, args, fallback, whnf) do
    reduce_nat(env, args, fallback, whnf)
  end

  defp reduce_by_metadata(env, %Reduction.NatInd{}, args, fallback, whnf) do
    reduce_nat(env, args, fallback, whnf)
  end

  defp reduce_by_metadata(env, %Reduction.ListRec{}, args, fallback, whnf) do
    reduce_list(env, args, fallback, whnf)
  end

  defp reduce_by_metadata(env, %Reduction.ListInd{}, args, fallback, whnf) do
    reduce_list(env, args, fallback, whnf)
  end

  defp reduce_bool(env, [_type, on_true, _on_false, %Const{name: true}], _fallback, whnf) do
    whnf.(env, on_true)
  end

  defp reduce_bool(env, [_type, _on_true, on_false, %Const{name: false}], _fallback, whnf) do
    whnf.(env, on_false)
  end

  defp reduce_bool(_env, _args, fallback, _whnf), do: {:stuck, fallback}

  defp reduce_nat(env, [_type, on_zero, _on_succ, %Const{name: :zero}], _fallback, whnf) do
    whnf.(env, on_zero)
  end

  defp reduce_nat(env, [_type, _on_zero, on_succ, %App{} = nat], fallback, whnf) do
    reduce_nat_succ(env, on_succ, nat, fallback, whnf)
  end

  defp reduce_nat(_env, _args, fallback, _whnf), do: {:stuck, fallback}

  defp reduce_nat_succ(env, on_succ, nat, fallback, whnf) do
    case Term.Application.collect(nat) do
      {%Const{name: :succ}, [pred]} ->
        recursive = replace_last_arg(fallback, pred)

        on_succ
        |> app(pred)
        |> app(recursive)
        |> then(&whnf.(env, &1))

      _other ->
        {:stuck, fallback}
    end
  end

  defp reduce_list(
         env,
         [_element_type, _result_type, on_nil, _on_cons, %App{} = list],
         fallback,
         whnf
       ) do
    case Term.Application.collect(list) do
      {%Const{name: :list_nil}, [_element_type]} ->
        whnf.(env, on_nil)

      {%Const{name: :list_cons}, [_element_type, head, tail]} ->
        recursive = replace_last_arg(fallback, tail)
        on_cons = list_on_cons(fallback)

        on_cons
        |> app(head)
        |> app(tail)
        |> app(recursive)
        |> then(&whnf.(env, &1))

      _other ->
        {:stuck, fallback}
    end
  end

  defp reduce_list(_env, _args, fallback, _whnf), do: {:stuck, fallback}

  defp replace_last_arg(%App{} = app, arg), do: %App{app | arg: arg}

  defp list_on_cons(app) do
    case Term.Application.collect(app) do
      {_recursor, [_element_type, _result_type, _on_nil, on_cons, _list]} -> on_cons
    end
  end

  defp app(fun, arg), do: %App{fun: fun, arg: arg}
end
