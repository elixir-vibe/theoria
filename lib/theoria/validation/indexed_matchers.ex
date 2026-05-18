defmodule Theoria.Validation.IndexedMatchers do
  @moduledoc "Validation helpers for explicit indexed matcher metadata packages."

  alias Theoria.Env
  alias Theoria.Equation.Info
  alias Theoria.Equation.Matcher.Indexed.Package
  alias Theoria.Equation.Matcher.Indexed.Vec, as: IndexedVec

  @doc "Builds and validates the validation-only indexed matcher package."
  @spec check(Env.t()) :: {:ok, Package.t()} | {:error, term()}
  def check(%Env{} = env) do
    with {:ok, package} <- Package.build(vec_info(), env),
         :ok <- Package.validate(package) do
      {:ok, package}
    end
  end

  @doc "Returns the validation-only indexed Vec matcher info package."
  @spec vec_info() :: Info.t()
  def vec_info, do: IndexedVec.info(:vec_validation_match, :vec_validation_source)
end
