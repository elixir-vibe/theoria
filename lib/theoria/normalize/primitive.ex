defmodule Theoria.Normalize.Primitive do
  @moduledoc "Primitive weak-head reductions for built-in recursors."

  alias Theoria.Env
  alias Theoria.Term
  alias Theoria.Term.{App, Const}

  @type whnf_fun :: (Env.t(), Term.t() -> Theoria.Normalize.result())

  @spec reduce(Env.t(), App.t(), whnf_fun()) :: Theoria.Normalize.result()
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

      _ ->
        {:ok, app}
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
        {:ok, fallback}
    end
  end

  defp app(fun, arg), do: %App{fun: fun, arg: arg}
end
