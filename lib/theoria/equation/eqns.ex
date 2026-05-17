defmodule Theoria.Equation.Eqns do
  @moduledoc "Lookup helpers for generated equation theorem metadata."

  alias Theoria.Env
  alias Theoria.Equation.Info
  alias Theoria.Equation.Lemma
  alias Theoria.Equation.MatcherEqns
  alias Theoria.Rewrite.Database
  alias Theoria.Rewrite.Rule

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

  @doc "Returns generated unfold equation lemma metadata for a definition."
  @spec unfold(Env.t(), atom()) :: {:ok, Lemma.t()} | {:error, term()}
  def unfold(%Env{} = env, name) when is_atom(name) do
    with {:ok, info} <- Info.fetch(env, name) do
      {:ok, Lemma.unfold_for(info)}
    end
  end

  @doc "Finds the source definition for a generated equation theorem name."
  @spec source(Env.t(), atom()) :: {:ok, atom()} | :error
  def source(%Env{} = env, theorem_name) when is_atom(theorem_name) do
    env
    |> Info.all()
    |> Enum.find_value(:error, fn info ->
      names =
        [Lemma.unfold_for(info).name | Enum.map(Lemma.generated_for(info), & &1.name)] ++
          Enum.map(MatcherEqns.generated(info), & &1.name)

      if theorem_name in names do
        {:ok, info.name}
      else
        false
      end
    end)
  end

  @doc "Installs generated equation theorems for one definition."
  @spec install(Env.t(), atom(), keyword()) ::
          {:ok, Env.t(), [Theoria.Theorem.t()]} | {:error, term()}
  def install(%Env{} = env, name, opts \\ []) when is_atom(name) do
    Lemma.add_generated_to_env(env, name, opts)
  end

  @doc "Installs all generated equation theorems in declaration order."
  @spec install_all(Env.t(), keyword()) ::
          {:ok, Env.t(), [Theoria.Theorem.t()]} | {:error, term()}
  def install_all(%Env{} = env, opts \\ []) do
    env
    |> Info.all()
    |> Enum.reduce_while({:ok, env, []}, fn info, {:ok, env, theorems} ->
      case Lemma.add_generated_to_env(env, info, opts) do
        {:ok, env, installed} -> {:cont, {:ok, env, prepend_reversed(installed, theorems)}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, env, theorems} -> {:ok, env, Enum.reverse(theorems)}
      {:error, _reason} = error -> error
    end
  end

  defp prepend_reversed(items, accumulator), do: Enum.reduce(items, accumulator, &[&1 | &2])

  @doc "Builds rewrite rules for generated equations of one definition."
  @spec rules(Env.t(), atom(), keyword()) :: {:ok, [Rule.t()]} | {:error, term()}
  def rules(%Env{} = env, name, opts \\ []) when is_atom(name) do
    with {:ok, lemmas} <- generated(env, name) do
      {:ok, Enum.map(lemmas, &Rule.from_lemma(&1, opts))}
    end
  end

  @doc "Builds a rewrite database from all generated equation metadata in an environment."
  @spec database(Env.t(), keyword()) :: Database.t()
  def database(%Env{} = env, opts \\ []) do
    env
    |> Info.all()
    |> Enum.flat_map(fn info ->
      info
      |> Lemma.generated_for(opts)
      |> Enum.map(&Rule.from_lemma(&1, opts))
    end)
    |> Database.new()
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
