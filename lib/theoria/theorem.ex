defmodule Theoria.Theorem do
  @moduledoc "A theorem accepted by the trusted kernel."

  alias Theoria.Env
  alias Theoria.Env.Constant
  alias Theoria.Kernel
  alias Theoria.Term

  @enforce_keys [:name, :type, :proof]
  defstruct [:name, :type, :proof, universe_params: []]

  @type t :: %__MODULE__{
          name: atom(),
          type: Term.t(),
          proof: Term.t(),
          universe_params: [atom()]
        }

  @doc "Checks every theorem registered by a `use Theoria.DSL` theorem module."
  @spec check_all(module(), Env.t()) :: {:ok, [t()]} | {:error, {atom(), Theoria.Error.t()}}
  def check_all(module, %Env{} = env) when is_atom(module) do
    module.__theoria_theorems__()
    |> Enum.reduce_while({:ok, []}, fn name, {:ok, checked} ->
      case check_one(module, name, env) do
        {:ok, %__MODULE__{} = theorem} -> {:cont, {:ok, [theorem | checked]}}
        {:error, error} -> {:halt, {:error, {name, error}}}
      end
    end)
    |> reverse_checked()
  end

  @doc "Returns trusted axioms used by a checked theorem."
  @spec axioms(Env.t(), t()) :: {:ok, MapSet.t(atom())}
  def axioms(%Env{} = env, %__MODULE__{type: type, proof: proof}) do
    dependencies = MapSet.union(Term.constants(type), Term.constants(proof))
    {:ok, collect_axioms(env, dependencies)}
  end

  @doc "Adds a checked theorem to an environment as an opaque theorem declaration."
  @spec add_to_env(Env.t(), t()) :: {:ok, Env.t()} | {:error, Theoria.Error.t()}
  def add_to_env(%Env{} = env, %__MODULE__{
        name: name,
        type: type,
        proof: proof,
        universe_params: universe_params
      }) do
    Kernel.add_theorem(env, name, type, proof, universe_params)
  end

  @doc "Checks and installs every theorem registered by a theorem module in order."
  @spec add_all_to_env(module(), Env.t()) ::
          {:ok, Env.t(), [t()]} | {:error, {atom(), Theoria.Error.t()}}
  def add_all_to_env(module, %Env{} = env) when is_atom(module) do
    module.__theoria_theorems__()
    |> Enum.reduce_while({:ok, env, []}, fn name, {:ok, env, checked} ->
      with {:ok, %__MODULE__{} = theorem} <- check_one(module, name, env),
           {:ok, env} <- add_to_env(env, theorem) do
        {:cont, {:ok, env, [theorem | checked]}}
      else
        {:error, error} -> {:halt, {:error, {name, error}}}
      end
    end)
    |> reverse_installed()
  end

  defp collect_axioms(env, dependencies) do
    Enum.reduce(dependencies, MapSet.new(), fn dependency, axioms ->
      MapSet.union(axioms, dependency_axioms(env, dependency))
    end)
  end

  defp dependency_axioms(env, dependency) do
    case {Env.fetch(env, dependency), Kernel.axioms(env, dependency)} do
      {{:ok, %Constant{kind: :axiom}}, {:ok, axioms}} -> MapSet.put(axioms, dependency)
      {_constant, {:ok, axioms}} -> axioms
      _unknown -> MapSet.new()
    end
  end

  defp check_one(module, name, env) do
    theorem_fun = String.to_existing_atom("#{name}_theorem")
    apply(module, theorem_fun, [env])
  end

  defp reverse_checked({:ok, checked}), do: {:ok, Enum.reverse(checked)}
  defp reverse_checked({:error, {_name, _error}} = error), do: error

  defp reverse_installed({:ok, env, checked}), do: {:ok, env, Enum.reverse(checked)}
  defp reverse_installed({:error, {_name, _error}} = error), do: error
end
