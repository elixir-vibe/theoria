defmodule Theoria.Equation.Eqns do
  @moduledoc "Lookup helpers for generated equation theorem metadata."

  alias Theoria.Env
  alias Theoria.Equation.Info
  alias Theoria.Equation.Lemma

  @doc "Returns generated equation theorem names for a definition."
  @spec get(Env.t(), atom()) :: {:ok, [atom()]} | {:error, term()}
  def get(%Env{} = env, name) when is_atom(name) do
    with {:ok, lemmas} <- generated(env, name) do
      {:ok, Enum.map(lemmas, & &1.name)}
    end
  end

  @doc "Returns generated equation lemma metadata for a definition."
  @spec generated(Env.t(), atom()) :: {:ok, [Lemma.t()]} | {:error, term()}
  def generated(%Env{} = env, name) when is_atom(name) do
    with {:ok, info} <- Info.fetch(env, name) do
      {:ok, Lemma.generated_for(info)}
    end
  end

  @doc "Returns true when every generated equation theorem for a definition is installed."
  @spec installed?(Env.t(), atom()) :: boolean()
  def installed?(%Env{} = env, name) when is_atom(name) do
    case get(env, name) do
      {:ok, names} -> Enum.all?(names, &match?({:ok, _constant}, Env.fetch(env, &1)))
      {:error, _reason} -> false
    end
  end
end
