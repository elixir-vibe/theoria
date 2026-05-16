defmodule Theoria.Library.Logic do
  @moduledoc """
  Basic logical constants and checked definitions.

  This module intentionally builds logic as environment declarations instead of
  adding more trusted kernel terms. `False`, `True`, `and`, and their
  eliminators/constructors are primitive constants for now; `not` is a checked
  definition on top of the core calculus.
  """

  alias Theoria.Env
  alias Theoria.Kernel

  import Theoria.Term

  @doc "The proposition universe used by the initial logic library."
  def prop, do: sort(0)

  @doc "Extends an environment with the initial logical constants and definitions."
  def extend(%Env{} = env) do
    with {:ok, env} <- Kernel.add_constant(env, :False, prop()),
         {:ok, env} <- Kernel.add_constant(env, :True, prop()),
         {:ok, env} <- Kernel.add_constant(env, :true_intro, const(:True)),
         {:ok, env} <- Kernel.add_constant(env, :false_elim, false_elim_type()),
         {:ok, env} <- Kernel.add_definition(env, :not, not_type(), not_value()),
         {:ok, env} <- Kernel.add_constant(env, :and, and_type()) do
      Kernel.add_constant(env, :and_intro, and_intro_type())
    end
  end

  @doc "Returns a new environment extended with the initial logic library."
  def env do
    extend(Env.new())
  end

  defp false_elim_type do
    forall(:a, prop(), arrow(const(:False), bvar(0)))
  end

  defp not_type do
    forall(:p, prop(), prop())
  end

  defp not_value do
    lam(:p, prop(), arrow(bvar(0), const(:False)))
  end

  defp and_type do
    forall(:p, prop(), forall(:q, prop(), prop()))
  end

  defp and_intro_type do
    forall(
      :p,
      prop(),
      forall(
        :q,
        prop(),
        forall(
          :hp,
          bvar(1),
          forall(
            :hq,
            bvar(1),
            const(:and)
            |> app(bvar(3))
            |> app(bvar(2))
          )
        )
      )
    )
  end
end
