defmodule Theoria.Kernel.Reference.Replay.Failure do
  @moduledoc """
  Structured diagnostic for a reference environment replay failure.

  Experimental in the 0.7 line; the shape may change before 1.0.
  """

  alias Theoria.Env
  alias Theoria.Env.Constant
  alias Theoria.Term

  @enforce_keys [:name, :phase, :declaration_kind, :reason, :direct_dependencies]
  defstruct [:name, :phase, :declaration_kind, :reason, :direct_dependencies, details: []]

  @type t :: %__MODULE__{
          name: Env.name(),
          phase: atom(),
          declaration_kind: atom() | nil,
          reason: term(),
          direct_dependencies: [atom()],
          details: keyword()
        }

  @spec new(Env.t(), Env.name(), atom(), term(), keyword()) :: t()
  def new(%Env{} = source_env, name, phase, reason, details \\ []) do
    constant = fetch_constant(source_env, name)

    %__MODULE__{
      name: name,
      phase: phase,
      declaration_kind: declaration_kind(constant),
      reason: reason,
      direct_dependencies: direct_dependencies(constant),
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
end
