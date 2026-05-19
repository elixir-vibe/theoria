defmodule Theoria.Kernel.Reference.Primitive do
  @moduledoc "Reference primitive reductions for recursor iota metadata."

  alias Theoria.Env
  alias Theoria.Env.{Constant, Recursor, Reduction}
  alias Theoria.Term
  alias Theoria.Term.{App, Const}

  @type whnf_fun :: (Env.t(), Term.t() -> {:ok, Term.t(), non_neg_integer()} | {:error, term()})
  @type defeq_fun :: (Env.t(), Term.t(), Term.t() -> boolean())
  @type result :: {:ok, Term.t(), non_neg_integer()} | {:error, term()} | {:stuck, App.t()}

  @doc "Attempts one reference primitive iota reduction."
  @spec reduce(Env.t(), App.t(), whnf_fun(), defeq_fun()) :: result()
  def reduce(%Env{} = env, %App{} = app, whnf, defeq)
      when is_function(whnf, 2) and is_function(defeq, 3) do
    with {%Const{name: name, levels: levels}, args} <- Term.Application.collect(app),
         {:ok, %Constant{reduction: %Reduction.Iota{}}} <- Env.fetch(env, name),
         {:ok, recursor} <- Env.fetch_recursor(env, name),
         {:ok, reduced} <- reduce_recursor(env, recursor, levels, args, defeq) do
      whnf.(env, reduced)
    else
      _other -> {:stuck, app}
    end
  end

  defp reduce_recursor(env, %Recursor{} = recursor, levels, args, defeq) do
    with {:ok, major} <- fetch_arg(args, Recursor.major_index(recursor)),
         {%Const{name: constructor}, constructor_args} <- Term.Application.collect(major),
         {:ok, rule} <- find_rule(recursor, constructor),
         {:ok, fields} <- trailing_fields(constructor_args, rule.field_count),
         {:ok, explicit_indices} <- explicit_indices(recursor, args),
         :ok <-
           indices_match?(env, recursor, rule, constructor_args, fields, explicit_indices, defeq) do
      instantiate_rule(recursor, levels, rule, args, fields)
    else
      _other -> :error
    end
  end

  defp find_rule(%Recursor{rules: rules}, constructor) do
    case Enum.find(rules, &(&1.constructor == constructor)) do
      nil -> :error
      rule -> {:ok, rule}
    end
  end

  defp trailing_fields(_args, 0), do: {:ok, []}

  defp trailing_fields(args, count) when length(args) >= count do
    {:ok, Enum.take(args, -count)}
  end

  defp trailing_fields(_args, _count), do: :error

  defp explicit_indices(%Recursor{num_indices: 0}, _args), do: {:ok, []}

  defp explicit_indices(%Recursor{} = recursor, args) do
    {:ok, Enum.slice(args, rule_prefix_count(recursor), recursor.num_indices)}
  end

  defp indices_match?(
         _env,
         %Recursor{num_indices: 0},
         _rule,
         _constructor_args,
         _fields,
         [],
         _defeq
       ) do
    :ok
  end

  defp indices_match?(env, %Recursor{} = recursor, rule, constructor_args, fields, indices, defeq) do
    replacements = Enum.reverse(Enum.take(constructor_args, recursor.num_params) ++ fields)
    patterns = Enum.map(rule.index_patterns, &instantiate_pattern(&1, replacements))

    if Enum.zip(patterns, indices)
       |> Enum.all?(fn {pattern, index} -> defeq.(env, pattern, index) end) do
      :ok
    else
      :error
    end
  end

  defp instantiate_rule(recursor, levels, rule, args, fields) do
    prefix = Enum.take(args, rule_prefix_count(recursor))
    suffix = Enum.drop(args, Recursor.major_index(recursor) + 1)
    level_substitution = Map.new(Enum.zip(recursor.universe_params, levels))
    rhs = Term.subst_levels(rule.rhs, level_substitution)
    {:ok, Enum.reduce(prefix ++ fields ++ suffix, rhs, &Term.app(&2, &1))}
  end

  defp rule_prefix_count(%Recursor{} = recursor) do
    recursor.num_params + recursor.num_motives + recursor.num_minors
  end

  defp instantiate_pattern(%Term.BVar{index: index}, replacements),
    do: Enum.fetch!(replacements, index)

  defp instantiate_pattern(%App{fun: fun, arg: arg}, replacements) do
    Term.app(instantiate_pattern(fun, replacements), instantiate_pattern(arg, replacements))
  end

  defp instantiate_pattern(term, _replacements), do: term

  defp fetch_arg(args, position) do
    case Enum.fetch(args, position) do
      {:ok, arg} -> {:ok, arg}
      :error -> :error
    end
  end
end
