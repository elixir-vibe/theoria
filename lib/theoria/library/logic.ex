defmodule Theoria.Library.Logic do
  @moduledoc """
  Basic logical constants and checked definitions.

  This module intentionally builds logic as environment declarations instead of
  adding more trusted kernel terms. `False`, `True`, `and`, and their
  eliminators/constructors are primitive constants for now; `not` is a checked
  definition on top of the core calculus.
  """

  alias Theoria.Elaborator
  alias Theoria.Env
  alias Theoria.Kernel
  alias Theoria.Syntax, as: S

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
    elaborate!(S.forall(:a, sprop(), S.arrow(S.const(:False), S.var(:a))))
  end

  defp not_type do
    elaborate!(S.forall(:p, sprop(), sprop()))
  end

  defp not_value do
    elaborate!(S.lam(:p, sprop(), S.arrow(S.var(:p), S.const(:False))))
  end

  defp and_type do
    elaborate!(S.forall(:p, sprop(), S.forall(:q, sprop(), sprop())))
  end

  defp and_intro_type do
    elaborate!(
      S.forall(
        :p,
        sprop(),
        S.forall(
          :q,
          sprop(),
          S.forall(
            :hp,
            S.var(:p),
            S.forall(
              :hq,
              S.var(:q),
              S.const(:and)
              |> S.app(S.var(:p))
              |> S.app(S.var(:q))
            )
          )
        )
      )
    )
  end

  defp sprop, do: S.sort(0)

  defp elaborate!(term), do: Elaborator.elaborate!(term)
end
