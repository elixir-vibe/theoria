defmodule Theoria.Kernel.MatcherAdmission do
  @moduledoc "Trusted-adjacent admission checks for matcher declarations."

  alias Theoria.Context
  alias Theoria.Env
  alias Theoria.Env.Matcher, as: EnvMatcher
  alias Theoria.Equation.Matcher.Spec, as: MatcherSpec
  alias Theoria.Error
  alias Theoria.Kernel
  alias Theoria.Kernel.AdmissionChecks
  alias Theoria.Term.Sort

  @doc "Checks and installs a matcher declaration package."
  @spec add(Env.t(), MatcherSpec.t()) :: {:ok, Env.t()} | {:error, Error.t()}
  def add(%Env{} = env, %MatcherSpec{} = spec) do
    metadata = MatcherSpec.metadata(spec)

    with :ok <- AdmissionChecks.ensure_fresh_declaration(env, spec.name),
         :ok <- AdmissionChecks.ensure_universe_params(spec.level_params),
         :ok <- ensure_matcher_metadata(metadata, spec),
         :ok <- AdmissionChecks.ensure_level_params(spec.type, spec.level_params),
         :ok <- AdmissionChecks.ensure_level_params(spec.value, spec.level_params),
         {:ok, %Sort{}} <- infer_sort(env, spec.type),
         :ok <- Kernel.check(env, Context.new(), spec.value, spec.type) do
      {:ok, Env.put_matcher(env, spec.name, spec.type, spec.value, spec.level_params, metadata)}
    end
  end

  defp infer_sort(env, type), do: Kernel.infer(env, Context.new(), type)

  defp ensure_matcher_metadata(%EnvMatcher{} = metadata, %MatcherSpec{} = spec) do
    cond do
      metadata.name != spec.name ->
        invalid_matcher_metadata(spec, metadata)

      metadata.source != spec.source ->
        invalid_matcher_metadata(spec, metadata)

      metadata.type != spec.type ->
        invalid_matcher_metadata(spec, metadata)

      metadata.value != spec.value ->
        invalid_matcher_metadata(spec, metadata)

      metadata.info.name != spec.name ->
        invalid_matcher_metadata(spec, metadata)

      metadata.mode != spec.mode ->
        invalid_matcher_metadata(spec, metadata)

      true ->
        :ok
    end
  end

  defp invalid_matcher_metadata(spec, metadata) do
    error(:invalid_declaration, kind: :matcher_metadata, name: spec.name, metadata: metadata)
  end

  defp error(reason, details), do: {:error, %Error{reason: reason, details: details}}
end
