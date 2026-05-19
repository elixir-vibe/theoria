defmodule Theoria.Kernel.AdmissionChecks do
  @moduledoc "Shared declaration-admission checks used by trusted kernel entrypoints."

  alias Theoria.Env
  alias Theoria.Error
  alias Theoria.Term

  @doc "Ensures a declaration name is not already present in the environment."
  @spec ensure_fresh_declaration(Env.t(), Env.name()) :: :ok | {:error, Error.t()}
  def ensure_fresh_declaration(%Env{} = env, name) do
    case Env.fetch(env, name) do
      :error -> :ok
      {:ok, _constant} -> error(:duplicate_declaration, name: name)
    end
  end

  @doc "Ensures universe parameters are atoms and contain no duplicates."
  @spec ensure_universe_params([atom()]) :: :ok | {:error, Error.t()}
  def ensure_universe_params(params) do
    cond do
      not Enum.all?(params, &is_atom/1) ->
        error(:invalid_universe_parameters, params: params)

      length(params) != MapSet.size(MapSet.new(params)) ->
        error(:duplicate_universe_parameter, params: params)

      true ->
        :ok
    end
  end

  @doc "Ensures all universe parameters in a term are declared by the enclosing declaration."
  @spec ensure_level_params(Term.t(), [atom()]) :: :ok | {:error, Error.t()}
  def ensure_level_params(term, allowed_params) do
    params = Term.level_params(term)
    allowed = MapSet.new(allowed_params)

    case MapSet.difference(params, allowed) |> MapSet.to_list() do
      [] -> :ok
      params -> error(:unknown_universe_parameter, params: Enum.sort(params))
    end
  end

  defp error(reason, details), do: {:error, %Error{reason: reason, details: details}}
end
