defmodule Theoria.Inductive.Admission do
  @moduledoc "Staged admission pipeline for inductive specifications."

  alias Theoria.Context
  alias Theoria.Env
  alias Theoria.Error
  alias Theoria.Inductive
  alias Theoria.Inductive.{Constructor, Declaration, Spec}
  alias Theoria.Kernel
  alias Theoria.Level
  alias Theoria.Term.Forall

  @type validation_result :: :ok | {:error, Error.t()}

  @spec check(Env.t(), Spec.t()) :: validation_result()
  def check(%Env{} = env, %Spec{} = spec) do
    with :ok <- Inductive.validate(spec),
         :ok <- check_family_signature(env, spec),
         {:ok, declarations} <- Inductive.declarations(spec),
         {:ok, type_env} <- install_inductive_type(env, declarations),
         :ok <- check_constructor_field_universes(type_env, spec),
         {:ok, _env} <- install_declarations(env, declarations) do
      :ok
    end
  end

  def check(_env, _spec), do: invalid(:invalid_spec)

  @spec plan(Env.t(), Spec.t()) :: {:ok, [Declaration.t()]} | {:error, Error.t()}
  def plan(%Env{} = env, %Spec{} = spec) do
    with :ok <- check(env, spec) do
      Inductive.declarations(spec)
    end
  end

  def plan(_env, _spec), do: invalid(:invalid_spec)

  @spec install(Env.t(), Spec.t()) :: {:ok, Env.t()} | {:error, Error.t()}
  def install(%Env{} = env, %Spec{} = spec) do
    with {:ok, declarations} <- plan(env, spec),
         {:ok, env} <- install_declarations(env, declarations),
         :ok <- Inductive.verify_env(env, spec) do
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

  defp run_validations(validations) do
    Enum.find_value(validations, :ok, fn validation ->
      case validation.() do
        :ok -> false
        {:error, _error} = error -> error
      end
    end)
  end

  defp invalid(problem, extra \\ []) do
    {:error, %Error{reason: :invalid_inductive, details: [problem: problem] ++ extra}}
  end
end
