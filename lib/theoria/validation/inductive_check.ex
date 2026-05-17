defmodule Theoria.Validation.InductiveCheck do
  @moduledoc "A Theoria-owned validation check for a built-in inductive specification."

  alias Theoria.Env
  alias Theoria.Inductive
  alias Theoria.Inductive.Spec

  @enforce_keys [:name, :spec, :dependency_env]
  defstruct [:name, :spec, :dependency_env, category: :inductive]

  @type t :: %__MODULE__{
          name: atom(),
          category: atom(),
          spec: Spec.t(),
          dependency_env: Env.t()
        }

  @doc "Builds an inductive validation check."
  @spec new(atom(), atom(), Spec.t(), Env.t()) :: t()
  def new(category, name, %Spec{} = spec, %Env{} = dependency_env)
      when is_atom(category) and is_atom(name) do
    %__MODULE__{category: category, name: name, spec: spec, dependency_env: dependency_env}
  end

  @doc "Checks the spec against its dependencies and verifies the installed prelude declaration."
  @spec check(Env.t(), t()) :: :ok | {:error, term()}
  def check(%Env{} = prelude, %__MODULE__{spec: spec, dependency_env: dependency_env}) do
    with :ok <- Inductive.check_spec(dependency_env, spec) do
      Inductive.verify_env(prelude, spec)
    end
  end
end

defimpl Theoria.Validation.Checkable, for: Theoria.Validation.InductiveCheck do
  alias Theoria.Validation.InductiveCheck

  def check(%InductiveCheck{} = check, env), do: InductiveCheck.check(env, check)
end
