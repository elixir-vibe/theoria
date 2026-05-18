defmodule Theoria.Equation.Realized do
  @moduledoc "A kernel-checked generated equation artifact that is not necessarily installed as a theorem."

  alias Theoria.Env
  alias Theoria.Equation.Identity
  alias Theoria.Kernel
  alias Theoria.Term
  alias Theoria.Theorem

  @enforce_keys [:identity, :type, :proof]
  defstruct [:identity, :type, :proof, universe_params: []]

  @type t :: %__MODULE__{
          identity: Identity.t(),
          type: Term.t(),
          proof: Term.t(),
          universe_params: [atom()]
        }

  @doc "Builds and kernel-checks a generated equation artifact."
  @spec check(Env.t(), Identity.t(), Term.t(), Term.t(), keyword()) ::
          {:ok, t()} | {:error, Theoria.Error.t()}
  def check(%Env{} = env, %Identity{} = identity, type, proof, opts \\ []) do
    with :ok <- Kernel.check(env, proof, type) do
      {:ok,
       %__MODULE__{
         identity: identity,
         type: type,
         proof: proof,
         universe_params: Keyword.get(opts, :universe_params, [])
       }}
    end
  end

  @doc "Converts a realized equation artifact to an installable theorem declaration."
  @spec to_theorem(t()) :: Theorem.t()
  def to_theorem(%__MODULE__{} = realized) do
    %Theorem{
      name: realized.identity,
      type: realized.type,
      proof: realized.proof,
      universe_params: realized.universe_params
    }
  end

  @doc "Installs a realized equation artifact as an opaque theorem declaration."
  @spec install(Env.t(), t()) :: {:ok, Env.t(), Theorem.t()} | {:error, Theoria.Error.t()}
  def install(%Env{} = env, %__MODULE__{} = realized) do
    theorem = to_theorem(realized)

    with {:ok, env} <- Theorem.add_to_env(env, theorem) do
      {:ok, env, theorem}
    end
  end
end
