defmodule Theoria.Normalize.Primitive do
  @moduledoc "Primitive weak-head reductions for declarations with iota metadata."

  alias Theoria.Env
  alias Theoria.Env.Constant
  alias Theoria.Env.Recursor
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
      {%Const{name: name, levels: levels}, args} ->
        reduce_constant(env, name, levels, args, app, whnf)

      _other ->
        {:stuck, app}
    end
  end

  defp reduce_constant(env, name, levels, args, fallback, whnf) do
    case Env.fetch(env, name) do
      {:ok, %Constant{reduction: %Reduction.Iota{}, metadata: %Recursor{} = recursor}} ->
        reduce_recursor(env, recursor, levels, args, fallback, whnf)

      _other ->
        {:stuck, fallback}
    end
  end

  defp reduce_recursor(env, %Recursor{} = recursor, levels, args, fallback, whnf) do
    major_index = Recursor.major_index(recursor)

    with {:ok, major} <- fetch_arg(args, major_index),
         {%Const{name: constructor}, constructor_args} <- Term.Application.collect(major),
         {:ok, rule} <- recursor_rule(recursor, constructor),
         {:ok, fields} <- constructor_fields(constructor_args, rule.field_count),
         {:ok, reduced} <- instantiate_rule(recursor, levels, rule, args, major_index, fields) do
      whnf.(env, reduced)
    else
      _other -> {:stuck, fallback}
    end
  end

  defp recursor_rule(%Recursor{rules: rules}, constructor) do
    case Enum.find(rules, &(&1.constructor == constructor)) do
      nil -> :error
      rule -> {:ok, rule}
    end
  end

  defp constructor_fields(_args, 0), do: {:ok, []}

  defp constructor_fields(args, field_count) when length(args) >= field_count do
    {:ok, Enum.take(args, -field_count)}
  end

  defp constructor_fields(_args, _field_count), do: :error

  defp instantiate_rule(recursor, levels, rule, recursor_args, major_index, fields) do
    prefix = Enum.take(recursor_args, major_index)
    suffix = Enum.drop(recursor_args, major_index + 1)
    rhs = Term.subst_levels(rule.rhs, Enum.zip(recursor.universe_params, levels) |> Map.new())
    {:ok, Enum.reduce(prefix ++ fields ++ suffix, rhs, &app(&2, &1))}
  end

  defp fetch_arg(args, position) do
    case Enum.fetch(args, position) do
      {:ok, arg} -> {:ok, arg}
      :error -> :error
    end
  end

  defp app(fun, arg), do: %App{fun: fun, arg: arg}
end
