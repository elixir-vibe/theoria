defmodule Theoria.Inductive do
  @moduledoc "Validation helpers for inductive specifications."

  alias Theoria.Env
  alias Theoria.Env.Constant
  alias Theoria.Env.Constructor, as: EnvConstructor
  alias Theoria.Env.Inductive, as: EnvInductive
  alias Theoria.Env.Recursor, as: EnvRecursor
  alias Theoria.Env.RecursorRule
  alias Theoria.Env.Reduction
  alias Theoria.Error

  alias Theoria.Inductive.{
    Constructor,
    Declaration,
    Generate,
    Index,
    Parameter,
    Report,
    Shape,
    Spec
  }

  alias Theoria.Context
  alias Theoria.Elaborator
  alias Theoria.Inductive.Recursor, as: SpecRecursor
  alias Theoria.Kernel
  alias Theoria.Level
  alias Theoria.Normalize
  alias Theoria.Syntax, as: S
  alias Theoria.Term
  alias Theoria.Term.{App, Const, Forall}

  @type validation_result :: :ok | {:error, Error.t()}

  @spec validate(Spec.t()) :: validation_result()
  def validate(%Spec{} = spec) do
    run_validations([
      fn -> validate_name(spec.name) end,
      fn -> validate_universe_params(spec.universe_params) end,
      fn -> validate_parameters(spec) end,
      fn -> validate_num_params(spec) end,
      fn -> validate_indices(spec) end,
      fn -> validate_terms(spec) end,
      fn -> validate_constructors(spec) end,
      fn -> validate_recursors(spec) end
    ])
  end

  def validate(_spec), do: invalid(:invalid_spec)

  @spec declarations(Spec.t()) :: {:ok, [Declaration.t()]} | {:error, Error.t()}
  def declarations(%Spec{} = spec) do
    with :ok <- validate(spec) do
      {:ok, build_declarations(spec)}
    end
  end

  def declarations(_spec), do: invalid(:invalid_spec)

  @spec report(Spec.t()) :: {:ok, Report.t()} | {:error, Error.t()}
  def report(%Spec{} = spec) do
    with {:ok, declarations} <- declarations(spec) do
      {:ok,
       %Report{
         name: spec.name,
         shape: shape(spec),
         universe_params: spec.universe_params,
         declarations: Enum.map(declarations, & &1.name)
       }}
    end
  end

  def report(_spec), do: invalid(:invalid_spec)

  @spec classify(Spec.t()) :: Shape.t()
  def classify(%Spec{} = spec), do: Shape.classify(spec)
  def classify(_spec), do: %Shape{kind: :unknown, constructors: %{}, parameters: []}

  @spec shape(Spec.t()) :: Shape.kind()
  def shape(%Spec{} = spec), do: classify(spec).kind
  def shape(_spec), do: :unknown

  @spec complete(Spec.t()) :: {:ok, Spec.t()} | {:error, Error.t()}
  def complete(%Spec{recursors: []} = spec) do
    case Generate.eliminators(spec) do
      {:ok, recursors} -> {:ok, %Spec{spec | recursors: recursors}}
      {:error, %Error{details: [problem: :unknown_shape]}} -> invalid(:unknown_inductive_shape)
      {:error, error} -> {:error, error}
    end
  end

  def complete(%Spec{} = spec), do: {:ok, spec}
  def complete(_spec), do: invalid(:invalid_spec)

  @spec verify_env(Env.t(), Spec.t()) :: validation_result()
  def verify_env(%Env{} = env, %Spec{} = spec) do
    with {:ok, declarations} <- declarations(spec) do
      Enum.reduce_while(declarations, :ok, &verify_declaration(env, &1, &2))
    end
  end

  def verify_env(_env, _spec), do: invalid(:invalid_spec)

  @spec check_declarations(Env.t(), Spec.t()) :: validation_result()
  def check_declarations(%Env{} = env, %Spec{} = spec) do
    with {:ok, declarations} <- declarations(spec),
         {:ok, _env} <- install_declarations(env, declarations) do
      :ok
    end
  end

  def check_declarations(_env, _spec), do: invalid(:invalid_spec)

  @spec check_spec(Env.t(), Spec.t()) :: validation_result()
  def check_spec(%Env{} = env, %Spec{} = spec) do
    with :ok <- validate(spec),
         :ok <- check_family_signature(env, spec),
         {:ok, declarations} <- declarations(spec),
         {:ok, type_env} <- install_inductive_type(env, declarations),
         :ok <- check_constructor_field_universes(type_env, spec) do
      check_declarations(env, spec)
    end
  end

  def check_spec(_env, _spec), do: invalid(:invalid_spec)

  @spec install(Env.t(), Spec.t()) :: {:ok, Env.t()} | {:error, Error.t()}
  def install(%Env{} = env, %Spec{} = spec) do
    with {:ok, declarations} <- declarations(spec),
         {:ok, env} <- install_declarations(env, declarations),
         :ok <- verify_env(env, spec) do
      {:ok, env}
    end
  end

  def install(_env, _spec), do: invalid(:invalid_spec)

  defp check_family_signature(env, %Spec{} = spec) do
    run_validations([
      fn -> check_type(env, spec.type, :invalid_inductive_type) end,
      fn -> check_named_types(env, spec.parameters, :invalid_parameter_type) end,
      fn -> check_named_types(env, spec.indices, :invalid_index_type) end
    ])
  end

  defp check_named_types(env, named_types, problem) do
    Enum.reduce_while(named_types, :ok, fn named, :ok ->
      case check_type(env, named.type, problem) do
        :ok ->
          {:cont, :ok}

        {:error, error} ->
          {:halt, {:error, %{error | details: Keyword.put(error.details, :name, named.name)}}}
      end
    end)
  end

  defp check_type(env, type, problem) do
    case Kernel.infer(env, type) do
      {:ok, %Theoria.Term.Sort{}} ->
        :ok

      {:ok, _other} ->
        invalid(problem)

      {:error, error} ->
        {:error, %Error{reason: :invalid_inductive, details: [problem: problem, cause: error]}}
    end
  end

  defp install_inductive_type(env, [
         %Declaration{name: name, type: type, universe_params: params, metadata: metadata} | _rest
       ]) do
    Kernel.add_constant(env, name, type, params, kind: :inductive, metadata: metadata)
  end

  defp check_constructor_field_universes(env, %Spec{} = spec) do
    result_level = inductive_result_level(spec.type)

    Enum.reduce_while(spec.constructors, :ok, fn constructor, :ok ->
      case check_constructor_field_universes(env, spec, constructor, result_level) do
        :ok -> {:cont, :ok}
        {:error, _error} = error -> {:halt, error}
      end
    end)
  end

  defp check_constructor_field_universes(env, spec, constructor, result_level) do
    {:ok, result} = Constructor.result(constructor, spec)

    parameter_context =
      result.binders
      |> Enum.take(length(spec.parameters))
      |> Enum.reduce(Context.new(), fn binder, context ->
        Context.push(context, binder.name, binder.domain)
      end)

    result.binders
    |> Enum.drop(length(spec.parameters))
    |> Enum.reduce_while(parameter_context, fn binder, context ->
      case check_field_universe(env, context, binder, result_level, constructor.name) do
        :ok -> {:cont, Context.push(context, binder.name, binder.domain)}
        {:error, _error} = error -> {:halt, error}
      end
    end)
    |> case do
      %Context{} -> :ok
      {:error, _error} = error -> error
    end
  end

  defp check_field_universe(env, context, binder, result_level, constructor_name) do
    case Kernel.infer(env, context, binder.domain) do
      {:ok, %Theoria.Term.Sort{level: field_level}} ->
        if Level.zero?(result_level) or Level.leq?(field_level, result_level) do
          :ok
        else
          invalid(:constructor_field_universe_too_large, constructor: constructor_name)
        end

      {:ok, _other} ->
        invalid(:constructor_field_not_type, constructor: constructor_name)

      {:error, error} ->
        {:error,
         %Error{
           reason: :invalid_inductive,
           details: [
             problem: :constructor_field_type_error,
             constructor: constructor_name,
             cause: error
           ]
         }}
    end
  end

  defp inductive_result_level(%Forall{body: body}), do: inductive_result_level(body)
  defp inductive_result_level(%Theoria.Term.Sort{level: level}), do: level

  defp install_declarations(env, declarations) do
    Enum.reduce_while(declarations, {:ok, env}, fn declaration, {:ok, env} ->
      case install_declaration(env, declaration) do
        {:ok, env} -> {:cont, {:ok, env}}
        {:error, error} -> {:halt, {:error, error}}
      end
    end)
  end

  defp install_declaration(%Env{} = env, %Declaration{
         kind: kind,
         name: name,
         type: type,
         universe_params: universe_params,
         reduction: reduction,
         metadata: metadata
       }) do
    Kernel.add_constant(env, name, type, universe_params,
      kind: kind,
      reduction: reduction,
      metadata: metadata
    )
  end

  defp verify_declaration(env, %Declaration{} = declaration, :ok) do
    case Env.fetch(env, declaration.name) do
      {:ok, constant} -> verify_constant(env, declaration, constant)
      :error -> env_mismatch(declaration.name, :missing)
    end
    |> case do
      :ok -> {:cont, :ok}
      {:error, _error} = error -> {:halt, error}
    end
  end

  defp verify_constant(env, declaration, %Constant{} = constant) do
    run_validations([
      fn -> verify_kind(declaration, constant) end,
      fn -> verify_type(env, declaration, constant) end,
      fn -> verify_universe_params(declaration, constant) end,
      fn -> verify_reduction(declaration, constant) end,
      fn -> verify_metadata(declaration, constant) end
    ])
  end

  defp verify_kind(%Declaration{kind: kind}, %Constant{kind: kind}), do: :ok
  defp verify_kind(%Declaration{name: name}, _constant), do: env_mismatch(name, :kind)

  defp verify_type(env, %Declaration{name: name, type: type}, %Constant{type: actual_type}) do
    if Normalize.defeq?(env, actual_type, type) do
      :ok
    else
      env_mismatch(name, :type)
    end
  end

  defp verify_universe_params(%Declaration{universe_params: params}, %Constant{
         universe_params: params
       }),
       do: :ok

  defp verify_universe_params(%Declaration{name: name}, _constant) do
    env_mismatch(name, :universe_params)
  end

  defp verify_reduction(%Declaration{reduction: reduction}, %Constant{reduction: reduction}),
    do: :ok

  defp verify_reduction(%Declaration{name: name}, _constant), do: env_mismatch(name, :reduction)

  defp verify_metadata(%Declaration{metadata: metadata}, %Constant{metadata: metadata}), do: :ok
  defp verify_metadata(%Declaration{name: name}, _constant), do: env_mismatch(name, :metadata)

  defp build_declarations(%Spec{} = spec) do
    [inductive_declaration(spec)] ++
      Enum.map(spec.constructors, &constructor_declaration(&1, spec)) ++
      Enum.map(spec.recursors, &recursor_declaration(&1, spec))
  end

  defp inductive_declaration(%Spec{name: name, type: type} = spec) do
    %Declaration{
      name: name,
      type: type,
      kind: :inductive,
      universe_params: declaration_params(spec, type),
      metadata: inductive_metadata(spec)
    }
  end

  defp constructor_declaration(%Constructor{name: name, type: type} = constructor, %Spec{} = spec) do
    %Declaration{
      name: name,
      type: type,
      kind: :constructor,
      universe_params: declaration_params(spec, type),
      metadata: constructor_metadata(spec, constructor)
    }
  end

  defp recursor_declaration(
         %SpecRecursor{name: name, type: type, reduction: reduction},
         %Spec{} = spec
       ) do
    %Declaration{
      name: name,
      type: type,
      kind: :recursor,
      universe_params: declaration_params(spec, type),
      reduction: reduction,
      metadata: recursor_metadata(spec, name, type, reduction)
    }
  end

  defp inductive_metadata(%Spec{} = spec) do
    %EnvInductive{
      name: spec.name,
      type: spec.type,
      universe_params: declaration_params(spec, spec.type),
      num_params: length(spec.parameters),
      num_indices: length(spec.indices),
      constructors: Enum.map(spec.constructors, & &1.name),
      inductives: [spec.name],
      recursive?: recursive_spec?(spec),
      reflexive?: reflexive_spec?(spec)
    }
  end

  defp constructor_metadata(%Spec{} = spec, %Constructor{} = constructor) do
    {:ok, result} = Constructor.result(constructor, spec)

    %EnvConstructor{
      name: constructor.name,
      type: constructor.type,
      universe_params: declaration_params(spec, constructor.type),
      inductive: spec.name,
      constructor_index: Enum.find_index(spec.constructors, &(&1.name == constructor.name)),
      num_params: length(spec.parameters),
      num_fields: length(result.binders) - length(spec.parameters)
    }
  end

  defp recursor_metadata(%Spec{} = spec, name, type, %Reduction.Iota{}) do
    recursor_params = declaration_params(spec, type)

    %EnvRecursor{
      name: name,
      type: type,
      universe_params: recursor_params,
      inductives: [spec.name],
      num_params: length(spec.parameters),
      num_indices: length(spec.indices),
      num_motives: 1,
      num_minors: length(spec.constructors),
      rules: recursor_rules(spec, name, recursor_params)
    }
  end

  defp recursor_metadata(_spec, _name, _type, _reduction), do: nil

  defp recursor_rules(%Spec{} = spec, recursor_name, recursor_params) do
    spec.constructors
    |> Enum.with_index()
    |> Enum.map(fn {constructor, index} ->
      {:ok, result} = Constructor.result(constructor, spec)

      %RecursorRule{
        constructor: constructor.name,
        field_count: length(result.binders) - length(spec.parameters),
        rhs: recursor_rule_rhs(spec, recursor_name, recursor_params, result, index)
      }
    end)
  end

  defp recursor_rule_rhs(
         %Spec{} = spec,
         recursor_name,
         recursor_params,
         result,
         constructor_index
       ) do
    prefix_names = Enum.map(spec.parameters, & &1.name) ++ [:motive] ++ minor_names(spec)
    fields = field_binders(result, length(spec.parameters))
    minor = S.var(Enum.at(minor_names(spec), constructor_index))

    body =
      recursor_rule_body(
        spec,
        recursor_name,
        recursor_params,
        prefix_names,
        result,
        fields,
        minor
      )

    (prefix_names ++ Enum.map(fields, & &1.name))
    |> Enum.reverse()
    |> Enum.reduce(body, fn name, body -> S.lam(name, S.sort(0), body) end)
    |> Elaborator.elaborate!()
  end

  defp recursor_rule_body(
         spec,
         recursor_name,
         recursor_params,
         prefix_names,
         result,
         fields,
         minor
       ) do
    Enum.reduce(fields, minor, fn field, body ->
      body = S.app(body, S.var(field.name))

      if recursive_field?(result, field.position, spec.name) do
        S.app(body, recursive_call(recursor_name, recursor_params, prefix_names, field.name))
      else
        body
      end
    end)
  end

  defp recursive_call(recursor_name, recursor_params, prefix_names, field_name) do
    levels = Enum.map(recursor_params, &Level.param/1)

    args = Enum.map(prefix_names, &S.var/1) ++ [S.var(field_name)]
    Enum.reduce(args, S.const(recursor_name, levels), fn arg, fun -> S.app(fun, arg) end)
  end

  defp minor_names(%Spec{} = spec) do
    spec.constructors
    |> Enum.with_index()
    |> Enum.map(fn {_constructor, index} -> String.to_atom("minor#{index}") end)
  end

  defp field_binders(result, parameter_count) do
    result.binders
    |> Enum.drop(parameter_count)
    |> Enum.with_index()
    |> Enum.map(fn {binder, index} ->
      %{name: field_name(binder.name, index), position: binder.depth}
    end)
  end

  defp field_name(:_, index), do: String.to_atom("field#{index}")
  defp field_name(name, _index), do: name

  defp recursive_field?(result, position, inductive) do
    result.binders
    |> Enum.at(position)
    |> case do
      %{domain: domain} -> application_head(domain) |> const_named?(inductive)
      nil -> false
    end
  end

  defp recursive_spec?(%Spec{} = spec) do
    Enum.any?(spec.constructors, fn constructor ->
      constructor.type
      |> constructor_argument_types(spec.name)
      |> Enum.any?(&(application_head(&1) |> const_named?(spec.name)))
    end)
  end

  defp reflexive_spec?(%Spec{} = spec) do
    Enum.any?(spec.constructors, fn constructor ->
      constructor.type
      |> constructor_argument_types(spec.name)
      |> Enum.any?(&match?(%Forall{}, &1))
    end)
  end

  defp const_named?(%Const{name: name}, name), do: true
  defp const_named?(_term, _name), do: false

  defp declaration_params(%Spec{universe_params: universe_params}, type) do
    params = Term.level_params(type)
    Enum.filter(universe_params, &MapSet.member?(params, &1))
  end

  defp run_validations(validations) do
    Enum.reduce_while(validations, :ok, fn validation, :ok ->
      case validation.() do
        :ok -> {:cont, :ok}
        {:error, _error} = error -> {:halt, error}
      end
    end)
  end

  defp validate_name(name) when is_atom(name), do: :ok
  defp validate_name(_name), do: invalid(:invalid_name)

  defp validate_universe_params(params) when is_list(params) do
    cond do
      not Enum.all?(params, &is_atom/1) ->
        invalid(:invalid_universe_parameters)

      length(params) != MapSet.size(MapSet.new(params)) ->
        invalid(:duplicate_universe_parameter)

      true ->
        :ok
    end
  end

  defp validate_universe_params(_params), do: invalid(:invalid_universe_parameters)

  defp validate_terms(%Spec{} = spec) do
    allowed = MapSet.new(spec.universe_params)

    spec
    |> all_terms()
    |> Enum.reduce_while(:ok, fn term, :ok ->
      unknown = term |> Term.level_params() |> MapSet.difference(allowed) |> MapSet.to_list()

      case unknown do
        [] -> {:cont, :ok}
        params -> {:halt, invalid(:unknown_universe_parameter, params: Enum.sort(params))}
      end
    end)
  end

  defp all_terms(%Spec{
         type: type,
         parameters: parameters,
         indices: indices,
         constructors: constructors,
         recursors: recursors
       }) do
    [type] ++
      Enum.map(parameters, & &1.type) ++
      Enum.map(indices, & &1.type) ++
      Enum.map(constructors, & &1.type) ++ Enum.map(recursors, & &1.type)
  end

  defp validate_parameters(%Spec{parameters: parameters}) when is_list(parameters) do
    cond do
      not Enum.all?(parameters, &match?(%Parameter{name: name} when is_atom(name), &1)) ->
        invalid(:invalid_parameters)

      duplicate_name = duplicate_name(parameters) ->
        invalid(:duplicate_declaration, name: duplicate_name)

      true ->
        :ok
    end
  end

  defp validate_parameters(_spec), do: invalid(:invalid_parameters)

  defp validate_num_params(%Spec{num_params: num_params, parameters: parameters})
       when is_integer(num_params) and num_params >= 0 do
    if num_params == length(parameters) do
      :ok
    else
      invalid(:parameter_count_mismatch)
    end
  end

  defp validate_num_params(_spec), do: invalid(:invalid_parameter_count)

  defp validate_indices(%Spec{indices: indices}) when is_list(indices) do
    cond do
      not Enum.all?(indices, &match?(%Index{name: name} when is_atom(name), &1)) ->
        invalid(:invalid_indices)

      duplicate_name = duplicate_name(indices) ->
        invalid(:duplicate_declaration, name: duplicate_name)

      true ->
        :ok
    end
  end

  defp validate_indices(_spec), do: invalid(:invalid_indices)

  defp validate_constructors(%Spec{constructors: constructors} = spec)
       when is_list(constructors) do
    run_validations([
      fn -> validate_named_declarations(constructors, Constructor, :constructors) end,
      fn -> validate_disjoint_names(spec) end,
      fn -> validate_constructor_scope(spec) end,
      fn -> validate_constructor_targets(spec) end,
      fn -> validate_constructor_parameters(spec) end,
      fn -> validate_constructor_positivity(spec) end
    ])
  end

  defp validate_constructors(_spec), do: invalid(:invalid_constructors)

  defp validate_recursors(%Spec{recursors: recursors} = spec) when is_list(recursors) do
    run_validations([
      fn -> validate_named_declarations(recursors, SpecRecursor, :recursors) end,
      fn -> validate_recursor_reductions(recursors) end,
      fn -> validate_eliminator_shapes(spec) end
    ])
  end

  defp validate_recursors(_spec), do: invalid(:invalid_recursors)

  defp validate_constructor_scope(%Spec{} = spec) do
    Enum.reduce_while(spec.constructors, :ok, fn constructor, :ok ->
      case constructor_scope_problem(constructor, spec) do
        nil -> {:cont, :ok}
        problem -> {:halt, invalid(problem, constructor: constructor.name)}
      end
    end)
  end

  defp constructor_scope_problem(%Constructor{} = constructor, %Spec{} = spec) do
    case Constructor.result(constructor, spec) do
      {:ok, result} ->
        cond do
          Enum.any?(result.binders, &(not Term.well_scoped?(&1.domain, &1.depth))) ->
            :constructor_argument_scope_mismatch

          Enum.any?(result.indices, &(not Term.well_scoped?(&1, length(result.binders)))) ->
            :constructor_index_scope_mismatch

          true ->
            nil
        end

      {:error, _error} ->
        :constructor_target_mismatch
    end
  end

  defp validate_constructor_targets(%Spec{constructors: constructors} = spec) do
    Enum.reduce_while(constructors, :ok, fn constructor, :ok ->
      case Constructor.result(constructor, spec) do
        {:ok, _result} ->
          {:cont, :ok}

        {:error, _error} ->
          {:halt, invalid(:constructor_target_mismatch, constructor: constructor.name)}
      end
    end)
  end

  defp validate_constructor_parameters(%Spec{parameters: [], indices: []}), do: :ok

  defp validate_constructor_parameters(%Spec{} = spec) do
    Enum.reduce_while(spec.constructors, :ok, fn constructor, :ok ->
      case constructor_parameter_problem(constructor, spec) do
        nil -> {:cont, :ok}
        problem -> {:halt, invalid(problem, constructor: constructor.name)}
      end
    end)
  end

  defp constructor_parameter_problem(%Constructor{} = constructor, %Spec{} = spec) do
    case Constructor.result(constructor, spec) do
      {:ok, result} ->
        expected_arity = length(spec.parameters) + length(spec.indices)

        cond do
          length(result.arguments) != expected_arity ->
            :constructor_result_arity_mismatch

          not parameter_binders_match?(spec.parameters, result.binders) ->
            :constructor_parameter_mismatch

          not parameter_result_args_match?(spec.parameters, result.binders, result.arguments) ->
            :constructor_parameter_mismatch

          Enum.any?(result.indices, &MapSet.member?(Term.constants(&1), spec.name)) ->
            :constructor_index_recursive_occurrence

          true ->
            nil
        end

      {:error, _error} ->
        :constructor_target_mismatch
    end
  end

  defp parameter_binders_match?(parameters, binders) do
    Enum.all?(parameters, fn %Parameter{name: name, type: type} ->
      case Enum.find(binders, &(&1.name == name)) do
        nil -> false
        binder -> binder.domain == type
      end
    end)
  end

  defp parameter_result_args_match?(parameters, binders, args) do
    Enum.zip(parameters, args)
    |> Enum.all?(fn {%Parameter{name: name}, arg} ->
      case Enum.find_index(binders, &(&1.name == name)) do
        nil -> false
        position -> arg == Term.bvar(length(binders) - position - 1)
      end
    end)
  end

  defp validate_recursor_reductions(recursors) do
    Enum.reduce_while(recursors, :ok, fn recursor, :ok ->
      if Reduction.known?(recursor.reduction) do
        {:cont, :ok}
      else
        {:halt, invalid(:invalid_reduction, recursor: recursor.name)}
      end
    end)
  end

  defp validate_eliminator_shapes(%Spec{recursors: []}), do: :ok

  defp validate_eliminator_shapes(%Spec{} = spec) do
    case expected_eliminators(spec) do
      {:ok, expected} -> compare_eliminators(spec.recursors, expected)
      :unknown -> :ok
    end
  end

  defp expected_eliminators(%Spec{} = spec) do
    case Generate.eliminators(%Spec{spec | recursors: []}) do
      {:ok, recursors} -> {:ok, recursors}
      {:error, %Error{details: [problem: :unknown_shape]}} -> :unknown
      {:error, _error} -> :unknown
    end
  end

  defp compare_eliminators(actual, expected) do
    actual_by_name = Map.new(actual, &{&1.name, &1})

    Enum.reduce_while(expected, :ok, fn expected, :ok ->
      case Map.fetch(actual_by_name, expected.name) do
        {:ok, actual} -> compare_eliminator(actual, expected)
        :error -> {:halt, invalid(:missing_eliminator, recursor: expected.name)}
      end
    end)
  end

  defp compare_eliminator(actual, expected) do
    cond do
      actual.reduction != expected.reduction ->
        {:halt, invalid(:eliminator_reduction_mismatch, recursor: actual.name)}

      actual.type != expected.type ->
        {:halt, invalid(:eliminator_type_mismatch, recursor: actual.name)}

      true ->
        {:cont, :ok}
    end
  end

  defp validate_constructor_positivity(%Spec{name: name, constructors: constructors}) do
    Enum.reduce_while(constructors, :ok, fn constructor, :ok ->
      if positive_constructor?(constructor.type, name) do
        {:cont, :ok}
      else
        {:halt, invalid(:non_positive_constructor, constructor: constructor.name)}
      end
    end)
  end

  defp positive_constructor?(type, inductive_name) do
    type
    |> constructor_argument_types(inductive_name)
    |> Enum.all?(&positive_occurrences?(&1, inductive_name, :positive))
  end

  defp constructor_argument_types(type, inductive_name) do
    collect_constructor_arguments(type, inductive_name, [])
  end

  defp collect_constructor_arguments(%Forall{domain: domain, body: body}, inductive_name, args) do
    if constructor_result?(body, inductive_name) do
      Enum.reverse([domain | args])
    else
      collect_constructor_arguments(body, inductive_name, [domain | args])
    end
  end

  defp collect_constructor_arguments(_type, _inductive_name, args), do: Enum.reverse(args)

  defp positive_occurrences?(%Const{name: name}, name, :negative), do: false
  defp positive_occurrences?(%Const{}, _name, _polarity), do: true
  defp positive_occurrences?(%Theoria.Term.Sort{}, _name, _polarity), do: true
  defp positive_occurrences?(%Theoria.Term.BVar{}, _name, _polarity), do: true

  defp positive_occurrences?(%App{fun: fun, arg: arg}, name, polarity) do
    positive_occurrences?(fun, name, polarity) and positive_occurrences?(arg, name, polarity)
  end

  defp positive_occurrences?(%Forall{domain: domain, body: body}, name, polarity) do
    positive_occurrences?(domain, name, flip_polarity(polarity)) and
      positive_occurrences?(body, name, polarity)
  end

  defp positive_occurrences?(%Theoria.Term.Lam{domain: domain, body: body}, name, polarity) do
    positive_occurrences?(domain, name, polarity) and positive_occurrences?(body, name, polarity)
  end

  defp positive_occurrences?(
         %Theoria.Term.Let{type: type, value: value, body: body},
         name,
         polarity
       ) do
    positive_occurrences?(type, name, polarity) and
      positive_occurrences?(value, name, polarity) and
      positive_occurrences?(body, name, polarity)
  end

  defp positive_occurrences?(
         %Theoria.Term.Eq{type: type, left: left, right: right},
         name,
         polarity
       ) do
    positive_occurrences?(type, name, polarity) and
      positive_occurrences?(left, name, polarity) and
      positive_occurrences?(right, name, polarity)
  end

  defp positive_occurrences?(%Theoria.Term.Refl{value: value}, name, polarity) do
    positive_occurrences?(value, name, polarity)
  end

  defp flip_polarity(:positive), do: :negative
  defp flip_polarity(:negative), do: :positive

  defp validate_named_declarations(declarations, module, field) do
    cond do
      not Enum.all?(
        declarations,
        &match?(%{__struct__: ^module, name: name} when is_atom(name), &1)
      ) ->
        invalid(:invalid_declaration, field: field)

      duplicate_name = duplicate_name(declarations) ->
        invalid(:duplicate_declaration, name: duplicate_name)

      true ->
        :ok
    end
  end

  defp validate_disjoint_names(%Spec{
         name: name,
         constructors: constructors,
         recursors: recursors
       }) do
    names = [name] ++ Enum.map(constructors, & &1.name) ++ Enum.map(recursors, & &1.name)

    case duplicate_name(names) do
      nil -> :ok
      name -> invalid(:duplicate_declaration, name: name)
    end
  end

  defp duplicate_name(items) do
    items
    |> Enum.map(fn
      %{name: name} -> name
      name -> name
    end)
    |> Enum.reduce_while(MapSet.new(), fn name, seen ->
      if MapSet.member?(seen, name) do
        {:halt, name}
      else
        {:cont, MapSet.put(seen, name)}
      end
    end)
    |> case do
      %MapSet{} -> nil
      name -> name
    end
  end

  defp constructor_targets_inductive?(type, inductive_name) do
    type
    |> peel_foralls()
    |> application_head()
    |> case do
      %Const{name: ^inductive_name} -> true
      _other -> false
    end
  end

  defp constructor_result?(%Forall{}, _inductive_name), do: false

  defp constructor_result?(type, inductive_name),
    do: constructor_targets_inductive?(type, inductive_name)

  defp peel_foralls(%Forall{body: body}), do: peel_foralls(body)
  defp peel_foralls(type), do: type

  defp application_head(%App{fun: fun}), do: application_head(fun)
  defp application_head(term), do: term

  defp env_mismatch(name, problem) do
    {:error, %Error{reason: :inductive_env_mismatch, details: [name: name, problem: problem]}}
  end

  defp invalid(reason, details \\ []) do
    {:error, %Error{reason: :invalid_inductive, details: Keyword.put(details, :problem, reason)}}
  end
end
