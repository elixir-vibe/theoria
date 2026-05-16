defmodule Theoria.Normalize.Primitive do
  @moduledoc "Primitive weak-head reductions for built-in recursors."

  alias Theoria.Env
  alias Theoria.Term
  alias Theoria.Term.{App, Const}

  @type fuel :: %{remaining_steps: non_neg_integer(), max_steps: pos_integer()}
  @type whnf_result :: {:ok, Term.t(), fuel()} | {:error, Theoria.Error.t()}
  @type whnf_fun :: (Env.t(), Term.t() -> whnf_result())
  @type result :: whnf_result() | {:stuck, App.t()}

  @spec reduce(Env.t(), App.t(), whnf_fun()) :: result()
  def reduce(%Env{} = env, %App{} = app, whnf) when is_function(whnf, 2) do
    case Term.Application.collect(app) do
      {%Const{name: :bool_rec}, [_type, on_true, _on_false, %Const{name: true}]} ->
        whnf.(env, on_true)

      {%Const{name: :bool_rec}, [_type, _on_true, on_false, %Const{name: false}]} ->
        whnf.(env, on_false)

      {%Const{name: :nat_rec}, [_type, on_zero, _on_succ, %Const{name: :zero}]} ->
        whnf.(env, on_zero)

      {%Const{name: :nat_rec}, [type, on_zero, on_succ, %App{} = nat]} ->
        reduce_nat_succ(env, type, on_zero, on_succ, nat, app, whnf)

      {%Const{name: :list_rec}, [_element_type, _result_type, on_nil, _on_cons, %App{} = list]} ->
        reduce_list(env, on_nil, list, app, whnf)

      _ ->
        {:stuck, app}
    end
  end

  defp reduce_nat_succ(env, type, on_zero, on_succ, nat, fallback, whnf) do
    case Term.Application.collect(nat) do
      {%Const{name: :succ}, [pred]} ->
        recursive =
          %Const{name: :nat_rec}
          |> app(type)
          |> app(on_zero)
          |> app(on_succ)
          |> app(pred)

        on_succ
        |> app(pred)
        |> app(recursive)
        |> then(&whnf.(env, &1))

      _ ->
        {:stuck, fallback}
    end
  end

  defp reduce_list(env, on_nil, list, fallback, whnf) do
    case Term.Application.collect(list) do
      {%Const{name: :list_nil}, [_element_type]} ->
        whnf.(env, on_nil)

      {%Const{name: :list_cons}, [_element_type, head, tail]} ->
        recursive = replace_last_arg(fallback, tail)

        fallback
        |> list_rec_on_cons()
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

  defp app(fun, arg), do: %App{fun: fun, arg: arg}
end
