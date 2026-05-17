defmodule Theoria.Kernel.RecursorRules do
  @moduledoc "Validation for trusted recursor iota rules."

  alias Theoria.Env
  alias Theoria.Env.Constant
  alias Theoria.Env.Constructor, as: EnvConstructor
  alias Theoria.Env.Recursor, as: EnvRecursor
  alias Theoria.Env.RecursorRule
  alias Theoria.Env.Reduction
  alias Theoria.Kernel, as: TypeChecker
  alias Theoria.Normalize
  alias Theoria.Term
  alias Theoria.Term.{App, BVar, Const, Forall, Sort}

  @spec validate(Env.t(), EnvRecursor.t()) :: :ok | :error
  def validate(%Env{} = env, %EnvRecursor{} = recursor) do
    recursor_env = put_unchecked_recursor(env, recursor)

    if Enum.all?(recursor.rules, &valid?(recursor_env, recursor, &1)) do
      :ok
    else
      :error
    end
  end

  defp valid?(env, %EnvRecursor{} = recursor, %RecursorRule{
         constructor: constructor,
         field_count: field_count,
         rhs: rhs,
         index_patterns: index_patterns
       }) do
    with true <- valid_indices?(recursor, index_patterns),
         true <- Term.well_scoped?(rhs),
         true <- well_scoped_index_patterns?(index_patterns, recursor.num_params + field_count),
         true <-
           MapSet.subset?(
             rule_level_params(rhs, index_patterns),
             MapSet.new(recursor.universe_params)
           ),
         true <- valid_type?(env, recursor, constructor, field_count, rhs),
         {:ok, recursor_inductive} <- recursor_inductive(recursor),
         {:ok, %EnvConstructor{inductive: inductive, num_fields: ^field_count}} <-
           Env.fetch_constructor(env, constructor),
         true <- inductive == recursor_inductive,
         true <- valid_index_patterns?(env, recursor, constructor, field_count, index_patterns) do
      true
    else
      _other -> false
    end
  end

  defp valid?(_env, _recursor, _rule), do: false

  defp valid_indices?(%EnvRecursor{num_indices: num_indices}, index_patterns) do
    is_list(index_patterns) and length(index_patterns) == num_indices
  end

  defp valid_index_patterns?(_env, %EnvRecursor{num_indices: 0}, _constructor, _field_count, []) do
    true
  end

  defp valid_index_patterns?(env, recursor, constructor, field_count, index_patterns) do
    case constructor_result_indices(env, recursor, constructor, field_count) do
      {:ok, expected_patterns} -> domain_lists_defeq?(env, index_patterns, expected_patterns)
      :error -> false
    end
  end

  defp constructor_result_indices(env, %EnvRecursor{} = recursor, constructor, field_count) do
    with {:ok, %Constant{type: constructor_type}} <- Env.fetch(env, constructor),
         {:ok, _domains, target} <-
           take_forall_domains(constructor_type, recursor.num_params + field_count),
         {%Const{name: inductive}, arguments} <- Term.Application.collect(target),
         {:ok, ^inductive} <- recursor_inductive(recursor),
         true <- length(arguments) == recursor.num_params + recursor.num_indices do
      {:ok, Enum.drop(arguments, recursor.num_params)}
    else
      _other -> :error
    end
  end

  defp well_scoped_index_patterns?(index_patterns, depth) do
    Enum.all?(index_patterns, &Term.well_scoped?(&1, depth))
  end

  defp rule_level_params(rhs, index_patterns) do
    Enum.reduce(index_patterns, Term.level_params(rhs), fn pattern, params ->
      MapSet.union(params, Term.level_params(pattern))
    end)
  end

  defp valid_type?(env, %EnvRecursor{} = recursor, constructor, field_count, rhs) do
    prefix_count = rule_prefix_count(recursor)
    domain_count = prefix_count + field_count

    with {:ok, rhs_type} <- TypeChecker.infer(env, rhs),
         {:ok, actual_domains, result} <- take_forall_domains(rhs_type, domain_count),
         false <- match?(%Forall{}, result),
         {:ok, expected_domains} <-
           expected_domains(env, recursor, constructor, field_count, actual_domains),
         {:ok, expected_result} <- expected_result(env, recursor, constructor, field_count) do
      domain_lists_defeq?(env, actual_domains, expected_domains) and
        Normalize.defeq?(env, result, expected_result)
    else
      _other -> false
    end
  end

  defp expected_domains(env, %EnvRecursor{} = recursor, constructor, field_count, actual_domains) do
    with {:ok, %Constant{type: constructor_type}} <- Env.fetch(env, constructor),
         {:ok, prefix_domains, _suffix} <-
           take_forall_domains(recursor.type, rule_prefix_count(recursor)),
         {:ok, field_domains} <-
           expected_field_domains(constructor_type, recursor, field_count, actual_domains) do
      {:ok, prefix_domains ++ field_domains}
    end
  end

  defp expected_field_domains(
         _constructor_type,
         %EnvRecursor{num_params: params} = recursor,
         field_count,
         actual_domains
       )
       when params > 0 do
    {:ok, Enum.slice(actual_domains, rule_prefix_count(recursor), field_count)}
  end

  defp expected_field_domains(
         constructor_type,
         %EnvRecursor{} = recursor,
         field_count,
         _actual_domains
       ) do
    with {:ok, constructor_domains, _target} <-
           take_forall_domains(constructor_type, recursor.num_params + field_count) do
      {:ok, Enum.drop(constructor_domains, recursor.num_params)}
    end
  end

  defp expected_result(env, %EnvRecursor{} = recursor, constructor, field_count) do
    with {:ok, prefix_domains, _suffix} <-
           take_forall_domains(recursor.type, rule_prefix_count(recursor)),
         {:ok, motive_type} <- Enum.fetch(prefix_domains, recursor.num_params),
         {:ok, constructor_app} <-
           constructor_application_in_rule_context(env, recursor, constructor, field_count),
         {:ok, indices} <- constructor_result_indices(env, recursor, constructor, field_count) do
      motive = motive_in_rule_context(recursor, field_count)

      result =
        if match?(%Sort{}, motive_type) do
          motive
        else
          indices
          |> Enum.map(&lift_constructor_context_term(&1, recursor, field_count))
          |> Kernel.++([constructor_app])
          |> Enum.reduce(motive, &%App{fun: &2, arg: &1})
        end

      {:ok, result}
    end
  end

  defp constructor_application_in_rule_context(
         env,
         %EnvRecursor{} = recursor,
         constructor,
         field_count
       ) do
    with {:ok, %Constant{universe_params: universe_params}} <- Env.fetch(env, constructor) do
      args =
        parameter_vars_in_rule_context(recursor, field_count) ++
          field_vars_in_rule_context(field_count)

      levels = Enum.map(universe_params, &Theoria.Level.param/1)

      constructor
      |> Term.const(levels)
      |> apply_arguments(args)
      |> then(&{:ok, &1})
    end
  end

  defp motive_in_rule_context(%EnvRecursor{} = recursor, field_count) do
    Term.bvar(field_count + recursor.num_minors + recursor.num_motives - 1)
  end

  defp parameter_vars_in_rule_context(%EnvRecursor{} = recursor, field_count) do
    for index <- 0..(recursor.num_params - 1)//1 do
      Term.bvar(
        field_count + recursor.num_minors + recursor.num_motives + recursor.num_params - 1 - index
      )
    end
  end

  defp field_vars_in_rule_context(0), do: []

  defp field_vars_in_rule_context(field_count) do
    for index <- 0..(field_count - 1)//1 do
      Term.bvar(field_count - 1 - index)
    end
  end

  defp lift_constructor_context_term(%BVar{index: index}, %EnvRecursor{} = recursor, field_count) do
    if index < field_count do
      Term.bvar(index)
    else
      Term.bvar(index + recursor.num_motives + recursor.num_minors)
    end
  end

  defp lift_constructor_context_term(%App{fun: fun, arg: arg}, recursor, field_count) do
    %App{
      fun: lift_constructor_context_term(fun, recursor, field_count),
      arg: lift_constructor_context_term(arg, recursor, field_count)
    }
  end

  defp lift_constructor_context_term(term, _recursor, _field_count), do: term

  defp apply_arguments(fun, args), do: Enum.reduce(args, fun, &%App{fun: &2, arg: &1})

  defp rule_prefix_count(%EnvRecursor{} = recursor) do
    recursor.num_params + recursor.num_motives + recursor.num_minors
  end

  defp take_forall_domains(term, count), do: take_forall_domains(term, count, [])
  defp take_forall_domains(term, 0, domains), do: {:ok, Enum.reverse(domains), term}

  defp take_forall_domains(%Forall{domain: domain, body: body}, count, domains) when count > 0 do
    take_forall_domains(body, count - 1, [domain | domains])
  end

  defp take_forall_domains(_term, _count, _domains), do: :error

  defp domain_lists_defeq?(env, actual_domains, expected_domains) do
    actual_domains
    |> Enum.zip(expected_domains)
    |> Enum.all?(fn {actual, expected} -> Normalize.defeq?(env, actual, expected) end)
  end

  defp put_unchecked_recursor(env, %EnvRecursor{} = recursor) do
    Env.put_constant(env, recursor.name, recursor.type, recursor.universe_params,
      kind: :recursor,
      reduction: %Reduction.Iota{},
      metadata: recursor
    )
  end

  defp recursor_inductive(%EnvRecursor{inductives: [inductive]}), do: {:ok, inductive}
  defp recursor_inductive(_recursor), do: :error
end
