defmodule Theoria.Prelude do
  @moduledoc """
  The standard Theoria environment.

  The prelude composes the built-in libraries in dependency order so users can
  start from a single environment instead of manually extending one library at a
  time.
  """

  alias Theoria.Env
  alias Theoria.Library.{Bool, List, Logic, Nat, Vec}

  @doc "Returns the standard environment with Logic, Bool, Nat, List, and Vec loaded."
  @spec env() :: {:ok, Env.t()} | {:error, Theoria.Error.t()}
  def env do
    Env.new()
    |> Logic.extend()
    |> extend_with(Bool)
    |> extend_with(Nat)
    |> extend_with(List)
    |> extend_with(Vec)
  end

  defp extend_with({:ok, %Env{} = env}, library), do: library.extend(env)
  defp extend_with({:error, error}, _library), do: {:error, error}
end
