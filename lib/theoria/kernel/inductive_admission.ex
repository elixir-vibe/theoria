defmodule Theoria.Kernel.InductiveAdmission do
  @moduledoc "Trusted-adjacent admission boundary for inductive declarations."

  alias Theoria.Env
  alias Theoria.Error
  alias Theoria.Inductive.Admission
  alias Theoria.Inductive.Spec

  @spec add(Env.t(), Spec.t()) :: {:ok, Env.t()} | {:error, Error.t()}
  def add(%Env{} = env, %Spec{} = spec), do: Admission.install(env, spec)
end
