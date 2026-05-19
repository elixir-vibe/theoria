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
    :missing_dependencies,
    :dependency_path,
    :checked_before_failure,
    :pending_after_failure
  ]
  defstruct [
    :name,
    :phase,
    :declaration_kind,
    :reason,
    :direct_dependencies,
    :transitive_dependencies,
    :missing_dependencies,
    :dependency_path,
    checked_before_failure: [],
    pending_after_failure: [],
    details: []
  ]

  @type t :: %__MODULE__{
          name: Env.name(),
          phase: atom(),
          declaration_kind: atom() | nil,
          reason: term(),
          direct_dependencies: [Env.name()],
          transitive_dependencies: [Env.name()],
          missing_dependencies: [Env.name()],
          dependency_path: [Env.name()],
          checked_before_failure: [Env.name()],
          pending_after_failure: [Env.name()],
          details: keyword()
        }

  @spec new(Env.t(), Env.name(), atom(), term(), keyword()) :: t()
  def new(%Env{} = source_env, name, phase, reason, details \\ []) do
    constant = fetch_constant(source_env, name)

    direct_dependencies = direct_dependencies(constant)
    missing_dependencies = missing_dependencies(source_env, direct_dependencies)

    %__MODULE__{
      name: name,
      phase: phase,
      declaration_kind: declaration_kind(constant),
      reason: reason,
      direct_dependencies: direct_dependencies,
      transitive_dependencies: transitive_dependencies(source_env, direct_dependencies),
      missing_dependencies: missing_dependencies,
      dependency_path: dependency_path(source_env, direct_dependencies, missing_dependencies),
      checked_before_failure: Keyword.get(details, :checked_before_failure, []),
      pending_after_failure: Keyword.get(details, :pending_after_failure, []),
      details: Keyword.drop(details, [:checked_before_failure, :pending_after_failure])
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

  @spec with_replay_context(t(), [Env.name()], [Env.name()]) :: t()
  def with_replay_context(%__MODULE__{} = failure, checked_before_failure, pending_after_failure) do
    %__MODULE__{
      failure
      | checked_before_failure: checked_before_failure,
        pending_after_failure: pending_after_failure
    }
  end

  defp dependency_path(_env, _dependencies, []), do: []

  defp dependency_path(env, dependencies, [target | _missing]) do
    Enum.find_value(dependencies, [], &find_dependency_path(env, &1, target, MapSet.new()))
  end

  defp find_dependency_path(_env, dependency, dependency, _seen), do: [dependency]

  defp find_dependency_path(env, dependency, target, seen) do
    unless MapSet.member?(seen, dependency) do
      dependency_path_from_fetch(env, dependency, target, MapSet.put(seen, dependency))
    end
  end

  defp dependency_path_from_fetch(env, dependency, target, seen) do
    case Env.fetch(env, dependency) do
      {:ok, %Constant{} = constant} ->
        constant
        |> direct_dependencies()
        |> Enum.find_value(
          &prepend_dependency(dependency, find_dependency_path(env, &1, target, seen))
        )

      :error ->
        nil
    end
  end

  defp prepend_dependency(_dependency, nil), do: nil
  defp prepend_dependency(dependency, path), do: [dependency | path]

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
