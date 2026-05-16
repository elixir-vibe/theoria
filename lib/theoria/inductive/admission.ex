defmodule Theoria.Inductive.Admission do
  @moduledoc "Staged admission pipeline for inductive specifications."

  alias Theoria.Env
  alias Theoria.Error
  alias Theoria.Inductive
  alias Theoria.Inductive.{Declaration, Spec}

  @type validation_result :: :ok | {:error, Error.t()}

  @spec check(Env.t(), Spec.t()) :: validation_result()
  def check(%Env{} = env, %Spec{} = spec), do: Inductive.check_spec(env, spec)
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
    with :ok <- check(env, spec) do
      Inductive.install(env, spec)
    end
  end

  def install(_env, _spec), do: invalid(:invalid_spec)

  defp invalid(problem) do
    {:error, %Error{reason: :invalid_inductive, details: [problem: problem]}}
  end
end
