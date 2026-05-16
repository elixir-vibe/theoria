defmodule Theoria.Inductive do
  @moduledoc "Validation helpers for inductive specifications."

  alias Theoria.Env
  alias Theoria.Env.Constant
  alias Theoria.Env.Reduction
  alias Theoria.Error
  alias Theoria.Inductive.{Constructor, Declaration, Generate, Recursor, Spec}
  alias Theoria.Kernel
  alias Theoria.Normalize
  alias Theoria.Term
  alias Theoria.Term.{App, Const, Forall}

  @type validation_result :: :ok | {:error, Error.t()}

  @spec validate(Spec.t()) :: validation_result()
  def validate(%Spec{} = spec) do
    run_validations([
      fn -> validate_name(spec.name) end,
      fn -> validate_universe_params(spec.universe_params) end,
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

  @spec shape(Spec.t()) :: :bool_like | :nat_like | :list_like | :unknown
  def shape(%Spec{constructors: constructors} = spec) do
    cond do
      bool_like?(constructors, spec.name) -> :bool_like
      nat_like?(constructors, spec.name) -> :nat_like
      list_like?(constructors, spec.name) -> :list_like
      true -> :unknown
    end
  end

  def shape(_spec), do: :unknown

  @spec complete(Spec.t()) :: {:ok, Spec.t()} | {:error, Error.t()}
  def complete(%Spec{recursors: []} = spec) do
    case shape(spec) do
      :bool_like -> {:ok, %Spec{spec | recursors: Generate.bool_eliminators(spec)}}
      :nat_like -> {:ok, %Spec{spec | recursors: Generate.nat_eliminators(spec)}}
      :list_like -> {:ok, %Spec{spec | recursors: Generate.list_eliminators(spec)}}
      :unknown -> invalid(:unknown_inductive_shape)
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

  @spec install(Env.t(), Spec.t()) :: {:ok, Env.t()} | {:error, Error.t()}
  def install(%Env{} = env, %Spec{} = spec) do
    with {:ok, declarations} <- declarations(spec),
         {:ok, env} <- install_declarations(env, declarations),
         :ok <- verify_env(env, spec) do
      {:ok, env}
    end
  end

  def install(_env, _spec), do: invalid(:invalid_spec)

  defp install_declarations(env, declarations) do
    Enum.reduce_while(declarations, {:ok, env}, fn declaration, {:ok, env} ->
      case install_declaration(env, declaration) do
        {:ok, env} -> {:cont, {:ok, env}}
        {:error, error} -> {:halt, {:error, error}}
      end
    end)
  end

  defp install_declaration(%Env{} = env, %Declaration{
         kind: :constant,
         name: name,
         type: type,
         universe_params: universe_params,
         reduction: reduction
       }) do
    Kernel.add_constant(env, name, type, universe_params, reduction: reduction)
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
      fn -> verify_reduction(declaration, constant) end
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

  defp build_declarations(%Spec{} = spec) do
    [inductive_declaration(spec)] ++
      Enum.map(spec.constructors, &constructor_declaration(&1, spec)) ++
      Enum.map(spec.recursors, &recursor_declaration(&1, spec))
  end

  defp inductive_declaration(%Spec{name: name, type: type} = spec) do
    %Declaration{
      name: name,
      type: type,
      kind: :constant,
      universe_params: declaration_params(spec, type)
    }
  end

  defp constructor_declaration(%Constructor{name: name, type: type}, %Spec{} = spec) do
    %Declaration{
      name: name,
      type: type,
      kind: :constant,
      universe_params: declaration_params(spec, type)
    }
  end

  defp recursor_declaration(
         %Recursor{name: name, type: type, reduction: reduction},
         %Spec{} = spec
       ) do
    %Declaration{
      name: name,
      type: type,
      kind: :constant,
      universe_params: declaration_params(spec, type),
      reduction: reduction
    }
  end

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

  defp all_terms(%Spec{type: type, constructors: constructors, recursors: recursors}) do
    [type] ++ Enum.map(constructors, & &1.type) ++ Enum.map(recursors, & &1.type)
  end

  defp validate_constructors(%Spec{constructors: constructors} = spec)
       when is_list(constructors) do
    run_validations([
      fn -> validate_named_declarations(constructors, Constructor, :constructors) end,
      fn -> validate_disjoint_names(spec) end,
      fn -> validate_constructor_targets(spec) end,
      fn -> validate_constructor_positivity(spec) end
    ])
  end

  defp validate_constructors(_spec), do: invalid(:invalid_constructors)

  defp validate_recursors(%Spec{recursors: recursors} = spec) when is_list(recursors) do
    run_validations([
      fn -> validate_named_declarations(recursors, Recursor, :recursors) end,
      fn -> validate_recursor_reductions(recursors) end,
      fn -> validate_eliminator_shapes(spec) end
    ])
  end

  defp validate_recursors(_spec), do: invalid(:invalid_recursors)

  defp validate_constructor_targets(%Spec{name: name, constructors: constructors}) do
    Enum.reduce_while(constructors, :ok, fn constructor, :ok ->
      if constructor_targets_inductive?(constructor.type, name) do
        {:cont, :ok}
      else
        {:halt, invalid(:constructor_target_mismatch, constructor: constructor.name)}
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
    case shape(%Spec{spec | recursors: []}) do
      :bool_like -> {:ok, Generate.bool_eliminators(spec)}
      :nat_like -> {:ok, Generate.nat_eliminators(spec)}
      :list_like -> {:ok, Generate.list_eliminators(spec)}
      :unknown -> :unknown
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

  defp collect_constructor_arguments(
         %Forall{name: :_, domain: domain, body: body},
         inductive_name,
         args
       ) do
    if constructor_targets_inductive?(body, inductive_name) do
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

  defp bool_like?([first, second], name) do
    nullary_constructor?(first.type, name) and nullary_constructor?(second.type, name)
  end

  defp bool_like?(_constructors, _name), do: false

  defp nat_like?([zero, succ], name) do
    nullary_constructor?(zero.type, name) and unary_recursive_constructor?(succ.type, name)
  end

  defp nat_like?(_constructors, _name), do: false

  defp list_like?([nil_constructor, cons], name) do
    constructor_targets_inductive?(nil_constructor.type, name) and
      list_cons_constructor?(cons.type, name)
  end

  defp list_like?(_constructors, _name), do: false

  defp nullary_constructor?(%Forall{}, _name), do: false

  defp nullary_constructor?(type, name) do
    constructor_targets_inductive?(type, name) and constructor_argument_types(type, name) == []
  end

  defp unary_recursive_constructor?(%Forall{name: :_, domain: domain, body: body}, name) do
    application_head(domain) == %Const{name: name} and constructor_targets_inductive?(body, name)
  end

  defp unary_recursive_constructor?(_type, _name), do: false

  defp list_cons_constructor?(%Forall{} = type, name) do
    constructor_targets_inductive?(type, name) and MapSet.member?(Term.constants(type), name)
  end

  defp list_cons_constructor?(_type, _name), do: false

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
