defmodule Theoria.Kernel.TheoremAdmission do
  @moduledoc "Trusted-adjacent admission checks for opaque theorem declarations."

  alias Theoria.Context
  alias Theoria.Env
  alias Theoria.Error
  alias Theoria.Kernel
  alias Theoria.Kernel.AdmissionChecks
  alias Theoria.Term
  alias Theoria.Term.Sort

  @spec add(Env.t(), Env.name(), Term.t(), Term.t(), [atom()]) ::
          {:ok, Env.t()} | {:error, Error.t()}
  def add(%Env{} = env, name, type, proof, universe_params \\ []) when is_list(universe_params) do
    with :ok <- AdmissionChecks.ensure_fresh_declaration(env, name),
         :ok <- AdmissionChecks.ensure_universe_params(universe_params),
         :ok <- AdmissionChecks.ensure_level_params(type, universe_params),
         :ok <- AdmissionChecks.ensure_level_params(proof, universe_params),
         {:ok, %Sort{}} <- infer_sort(env, type),
         :ok <- Kernel.check(env, Context.new(), proof, type) do
      {:ok, Env.put_theorem(env, name, type, proof, universe_params)}
    end
  end

  defp infer_sort(env, type) do
    case Kernel.infer(env, Context.new(), type) do
      {:ok, %Sort{} = sort} -> {:ok, sort}
      {:ok, actual} -> {:error, %Error{reason: :expected_sort, details: [type: actual]}}
      {:error, error} -> {:error, error}
    end
  end
end
