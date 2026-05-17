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
    with {:ok, %Constant{reduction: %Reduction.Iota{}}} <- Env.fetch(env, name),
         {:ok, recursor} <- Env.fetch_recursor(env, name) do
      reduce_recursor(env, recursor, levels, args, fallback, whnf)
    else
      _other -> {:stuck, fallback}
    end
  end

  defp reduce_recursor(env, %Recursor{} = recursor, levels, args, fallback, whnf) do
    major_index = Recursor.major_index(recursor)

    with {:ok, major} <- fetch_arg(args, major_index),
         {%Const{name: constructor}, constructor_args} <- Term.Application.collect(major),
         {:ok, rule} <- recursor_rule(recursor, constructor),
         {:ok, fields} <- constructor_fields(constructor_args, rule.field_count),
         {:ok, explicit_indices} <- explicit_indices(recursor, args),
         :ok <-
           match_index_patterns(env, recursor, rule, constructor_args, fields, explicit_indices),
         {:ok, reduced} <- instantiate_rule(recursor, levels, rule, args, fields) do
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

  defp explicit_indices(%Recursor{num_indices: 0}, _recursor_args), do: {:ok, []}

  defp explicit_indices(%Recursor{} = recursor, recursor_args) do
    prefix_count = rule_prefix_count(recursor)
    {:ok, Enum.slice(recursor_args, prefix_count, recursor.num_indices)}
  end

  defp match_index_patterns(
         _env,
         %Recursor{num_indices: 0},
         _rule,
         _constructor_args,
         _fields,
         []
       ),
       do: :ok

  defp match_index_patterns(
         env,
         %Recursor{} = recursor,
         rule,
         constructor_args,
         fields,
         explicit_indices
       ) do
    params = Enum.take(constructor_args, recursor.num_params)
    replacements = Enum.reverse(params ++ fields)

    patterns = Enum.map(rule.index_patterns, &instantiate_pattern(&1, replacements))

    if Enum.zip(patterns, explicit_indices)
       |> Enum.all?(fn {pattern, index} -> Theoria.Normalize.defeq?(env, pattern, index) end) do
      :ok
    else
      :error
    end
  end

  defp instantiate_rule(recursor, levels, rule, recursor_args, fields) do
    prefix = Enum.take(recursor_args, rule_prefix_count(recursor))
    suffix = Enum.drop(recursor_args, Recursor.major_index(recursor) + 1)
    rhs = Term.subst_levels(rule.rhs, Enum.zip(recursor.universe_params, levels) |> Map.new())
    {:ok, Enum.reduce(prefix ++ fields ++ suffix, rhs, &app(&2, &1))}
  end

  defp rule_prefix_count(%Recursor{} = recursor) do
    recursor.num_params + recursor.num_motives + recursor.num_minors
  end

  defp instantiate_pattern(%Term.BVar{index: index}, replacements),
    do: Enum.fetch!(replacements, index)

  defp instantiate_pattern(%App{fun: fun, arg: arg}, replacements) do
    app(instantiate_pattern(fun, replacements), instantiate_pattern(arg, replacements))
  end

  defp instantiate_pattern(term, _replacements), do: term

  defp fetch_arg(args, position) do
    case Enum.fetch(args, position) do
      {:ok, arg} -> {:ok, arg}
      :error -> :error
    end
  end

  defp app(fun, arg), do: %App{fun: fun, arg: arg}
end
