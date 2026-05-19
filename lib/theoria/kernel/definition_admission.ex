defmodule Theoria.Kernel.DefinitionAdmission do
  @moduledoc "Trusted-adjacent admission checks for transparent definitions."

  alias Theoria.Context
  alias Theoria.Env
  alias Theoria.Equation.Info
  alias Theoria.Error
  alias Theoria.Kernel
  alias Theoria.Kernel.AdmissionChecks
  alias Theoria.Term
  alias Theoria.Term.Sort

  @doc "Checks and installs a transparent definition declaration."
  @spec add(Env.t(), Env.name(), Term.t(), Term.t(), [atom()], keyword()) ::
          {:ok, Env.t()} | {:error, Error.t()}
  def add(%Env{} = env, name, type, value, universe_params \\ [], opts \\ [])
      when is_list(universe_params) and is_list(opts) do
    with :ok <- AdmissionChecks.ensure_fresh_declaration(env, name),
         :ok <- AdmissionChecks.ensure_universe_params(universe_params),
         :ok <- ensure_definition_metadata(Keyword.get(opts, :metadata), name, type, value),
         :ok <- AdmissionChecks.ensure_level_params(type, universe_params),
         :ok <- AdmissionChecks.ensure_level_params(value, universe_params),
         {:ok, %Sort{}} <- Kernel.infer(env, Context.new(), type),
         :ok <- Kernel.check(env, Context.new(), value, type) do
      {:ok, Env.put_definition(env, name, type, value, universe_params, opts)}
    end
  end

  defp ensure_definition_metadata(nil, _name, _type, _value), do: :ok

  defp ensure_definition_metadata(%Info{name: name, type: type, value: value}, name, type, value),
    do: :ok

  defp ensure_definition_metadata(%Info{} = metadata, name, _type, _value) do
    error(:invalid_declaration, kind: :equation_metadata, name: name, metadata: metadata)
  end

  defp ensure_definition_metadata(metadata, name, _type, _value) do
    error(:invalid_declaration, kind: :definition_metadata, name: name, metadata: metadata)
  end

  defp error(reason, details), do: {:error, %Error{reason: reason, details: details}}
end
