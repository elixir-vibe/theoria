defmodule Theoria.Normalize.Primitive do
  @moduledoc "Primitive weak-head reductions for built-in recursors."

  alias Theoria.Env
  alias Theoria.Term
  alias Theoria.Term.{App, Const}

  @type fuel :: Theoria.Normalize.Fuel.t()
  @type whnf_result :: {:ok, Term.t(), fuel()} | {:error, Theoria.Error.t()}
  @type whnf_fun :: (Env.t(), Term.t() -> whnf_result())
  @type result :: whnf_result() | {:stuck, App.t()}

  @spec reduce(Env.t(), App.t(), whnf_fun()) :: result()
  def reduce(%Env{} = env, %App{} = app, whnf) when is_function(whnf, 2) do
    case Term.Application.collect(app) do
      {%Const{name: name}, args} -> reduce_collected(env, name, args, app, whnf)
      _other -> {:stuck, app}
    end
  end

  defp reduce_collected(env, name, args, fallback, whnf) when name in [:bool_rec, :bool_ind] do
    reduce_bool(env, args, fallback, whnf)
  end

  defp reduce_collected(env, :nat_rec, args, fallback, whnf) do
    reduce_nat(env, args, fallback, whnf, &reduce_nat_succ/5)
  end

  defp reduce_collected(env, :nat_ind, args, fallback, whnf) do
    reduce_nat(env, args, fallback, whnf, &reduce_nat_ind_succ/5)
  end

  defp reduce_collected(env, :list_rec, args, fallback, whnf) do
    reduce_list(env, args, fallback, whnf, &reduce_list_rec/5)
  end

  defp reduce_collected(env, :list_ind, args, fallback, whnf) do
    reduce_list(env, args, fallback, whnf, &reduce_list_ind/5)
  end

  defp reduce_collected(_env, _name, _args, fallback, _whnf), do: {:stuck, fallback}

  defp reduce_bool(env, [_type, on_true, _on_false, %Const{name: true}], _fallback, whnf) do
    whnf.(env, on_true)
  end

  defp reduce_bool(env, [_type, _on_true, on_false, %Const{name: false}], _fallback, whnf) do
    whnf.(env, on_false)
  end

  defp reduce_bool(_env, _args, fallback, _whnf), do: {:stuck, fallback}

  defp reduce_nat(env, [_type, on_zero, _on_succ, %Const{name: :zero}], _fallback, whnf, _succ) do
    whnf.(env, on_zero)
  end

  defp reduce_nat(env, [_type, _on_zero, on_succ, %App{} = nat], fallback, whnf, succ) do
    succ.(env, on_succ, nat, fallback, whnf)
  end

  defp reduce_nat(_env, _args, fallback, _whnf, _succ), do: {:stuck, fallback}

  defp reduce_list(
         env,
         [_element_type, _result_type, on_nil, _on_cons, %App{} = list],
         fallback,
         whnf,
         reducer
       ) do
    reducer.(env, on_nil, list, fallback, whnf)
  end

  defp reduce_list(_env, _args, fallback, _whnf, _reducer), do: {:stuck, fallback}

  defp reduce_nat_succ(env, on_succ, nat, fallback, whnf) do
    reduce_nat_succ_like(env, on_succ, nat, fallback, whnf)
  end

  defp reduce_nat_ind_succ(env, on_succ, nat, fallback, whnf) do
    reduce_nat_succ_like(env, on_succ, nat, fallback, whnf)
  end

  defp reduce_nat_succ_like(env, on_succ, nat, fallback, whnf) do
    case Term.Application.collect(nat) do
      {%Const{name: :succ}, [pred]} ->
        recursive = replace_last_arg(fallback, pred)

        on_succ
        |> app(pred)
        |> app(recursive)
        |> then(&whnf.(env, &1))

      _ ->
        {:stuck, fallback}
    end
  end

  defp reduce_list_rec(env, on_nil, list, fallback, whnf) do
    reduce_list_succ_like(env, on_nil, list, fallback, whnf, &list_rec_on_cons/1)
  end

  defp reduce_list_ind(env, on_nil, list, fallback, whnf) do
    reduce_list_succ_like(env, on_nil, list, fallback, whnf, &list_ind_on_cons/1)
  end

  defp reduce_list_succ_like(env, on_nil, list, fallback, whnf, on_cons_fun) do
    case Term.Application.collect(list) do
      {%Const{name: :list_nil}, [_element_type]} ->
        whnf.(env, on_nil)

      {%Const{name: :list_cons}, [_element_type, head, tail]} ->
        recursive = replace_last_arg(fallback, tail)

        fallback
        |> on_cons_fun.()
        |> app(head)
        |> app(tail)
        |> app(recursive)
        |> then(&whnf.(env, &1))

      _ ->
        {:stuck, fallback}
    end
  end

  defp replace_last_arg(%App{} = app, arg), do: %App{app | arg: arg}

  defp list_rec_on_cons(app) do
    case Term.Application.collect(app) do
      {%Const{name: :list_rec}, [_element_type, _result_type, _on_nil, on_cons, _list]} -> on_cons
    end
  end

  defp list_ind_on_cons(app) do
    case Term.Application.collect(app) do
      {%Const{name: :list_ind}, [_element_type, _motive, _on_nil, on_cons, _list]} -> on_cons
    end
  end

  defp app(fun, arg), do: %App{fun: fun, arg: arg}
end
