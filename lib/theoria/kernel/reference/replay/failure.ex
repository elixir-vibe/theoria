defmodule Theoria.Kernel.Reference.Replay.Failure do
  @moduledoc """
  Structured diagnostic for a reference environment replay failure.

  Experimental before 1.0; the shape may change.
  """

  alias Theoria.Env
  alias Theoria.Env.Constant
  alias Theoria.Term

  @enforce_keys [
    :name,
    :phase,
    :declaration_kind,
    :reason,
    :direct_dependencies,
    :transitive_dependencies,
    :missing_dependencies
  ]
  defstruct [
    :name,
    :phase,
    :declaration_kind,
    :reason,
    :direct_dependencies,
    :transitive_dependencies,
    :missing_dependencies,
    details: []
  ]

  @type t :: %__MODULE__{
          name: Env.name(),
          phase: atom(),
          declaration_kind: atom() | nil,
          reason: term(),
          direct_dependencies: [atom()],
          transitive_dependencies: [atom()],
          missing_dependencies: [atom()],
          details: keyword()
        }

  @spec new(Env.t(), Env.name(), atom(), term(), keyword()) :: t()
  def new(%Env{} = source_env, name, phase, reason, details \\ []) do
    constant = fetch_constant(source_env, name)

    direct_dependencies = direct_dependencies(constant)

    %__MODULE__{
      name: name,
      phase: phase,
      declaration_kind: declaration_kind(constant),
      reason: reason,
      direct_dependencies: direct_dependencies,
      transitive_dependencies: transitive_dependencies(source_env, direct_dependencies),
      missing_dependencies: missing_dependencies(source_env, direct_dependencies),
      details: details
    }
  end

  defp fetch_constant(env, name) do
    case Env.fetch(env, name) do
      {:ok, %Constant{} = constant} -> constant
      :error -> nil
    end
  end

  defp declaration_kind(%Constant{kind: kind}), do: kind
  defp declaration_kind(nil), do: nil

  defp direct_dependencies(%Constant{type: type, value: nil}),
    do: type |> Term.constants() |> MapSet.to_list() |> Enum.sort()

  defp direct_dependencies(%Constant{type: type, value: value}) do
    type
    |> Term.constants()
    |> MapSet.union(Term.constants(value))
    |> MapSet.to_list()
    |> Enum.sort()
  end

  defp direct_dependencies(nil), do: []

  defp transitive_dependencies(env, dependencies) do
    dependencies
    |> Enum.reduce(MapSet.new(), &collect_transitive_dependency(env, &1, &2))
    |> MapSet.to_list()
    |> Enum.sort()
  end

  defp collect_transitive_dependency(env, dependency, seen) do
    if MapSet.member?(seen, dependency) do
      seen
    else
      seen = MapSet.put(seen, dependency)

      case Env.fetch(env, dependency) do
        {:ok, %Constant{} = constant} ->
          constant
          |> direct_dependencies()
          |> Enum.reduce(seen, &collect_transitive_dependency(env, &1, &2))

        :error ->
          seen
      end
    end
  end

  defp missing_dependencies(env, dependencies) do
    dependencies
    |> Enum.flat_map(&collect_missing_dependency(env, &1, MapSet.new()))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp collect_missing_dependency(env, dependency, seen) do
    if MapSet.member?(seen, dependency) do
      []
    else
      seen = MapSet.put(seen, dependency)

      case Env.fetch(env, dependency) do
        {:ok, %Constant{} = constant} ->
          constant
          |> direct_dependencies()
          |> Enum.flat_map(&collect_missing_dependency(env, &1, seen))

        :error ->
          [dependency]
      end
    end
  end
end
