defmodule Theoria.Inductive do
  @moduledoc "Validation helpers for inductive specifications."

  alias Theoria.Env.Reduction
  alias Theoria.Error
  alias Theoria.Inductive.{Constructor, Declaration, Recursor, Spec}
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

  defp build_declarations(%Spec{} = spec) do
    [inductive_declaration(spec)] ++
      Enum.map(spec.constructors, &constructor_declaration(&1, spec)) ++
      Enum.map(spec.recursors, &recursor_declaration(&1, spec))
  end

  defp inductive_declaration(%Spec{name: name, type: type, universe_params: universe_params}) do
    %Declaration{name: name, type: type, kind: :constant, universe_params: universe_params}
  end

  defp constructor_declaration(%Constructor{name: name, type: type}, %Spec{
         universe_params: universe_params
       }) do
    %Declaration{name: name, type: type, kind: :constant, universe_params: universe_params}
  end

  defp recursor_declaration(%Recursor{name: name, type: type, reduction: reduction}, %Spec{
         universe_params: universe_params
       }) do
    %Declaration{
      name: name,
      type: type,
      kind: :constant,
      universe_params: universe_params,
      reduction: reduction
    }
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
      fn -> validate_constructor_targets(spec) end
    ])
  end

  defp validate_constructors(_spec), do: invalid(:invalid_constructors)

  defp validate_recursors(%Spec{recursors: recursors}) when is_list(recursors) do
    run_validations([
      fn -> validate_named_declarations(recursors, Recursor, :recursors) end,
      fn -> validate_recursor_reductions(recursors) end
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

  defp invalid(reason, details \\ []) do
    {:error, %Error{reason: :invalid_inductive, details: Keyword.put(details, :problem, reason)}}
  end
end
