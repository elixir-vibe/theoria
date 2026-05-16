defmodule Theoria.Library.Nat do
  @moduledoc """
  Initial natural number declarations and primitive recursion.
  """

  alias Theoria.Env
  alias Theoria.Kernel
  alias Theoria.Level

  import Theoria.DSL, except: [type: 1]

  @doc "The core universe for `Type 0`."
  def type, do: Theoria.Term.sort(1)

  @doc "Extends an environment with natural number declarations."
  def extend(%Env{} = env) do
    with {:ok, env} <- Kernel.add_constant(env, :Nat, type()),
         {:ok, env} <- Kernel.add_constant(env, :zero, Theoria.Term.const(:Nat)),
         {:ok, env} <- Kernel.add_constant(env, :succ, succ_type()),
         {:ok, env} <- Kernel.add_constant(env, :nat_rec, nat_rec_type(), [:u]),
         {:ok, env} <- Kernel.add_constant(env, :nat_ind, nat_ind_type(), [:u]) do
      Kernel.add_definition(env, :nat_add, nat_add_type(), nat_add_value())
    end
  end

  @doc "Returns a new environment extended with natural number declarations."
  def env do
    extend(Env.new())
  end

  defp succ_type do
    elab!(arrow(const(:Nat), const(:Nat)))
  end

  defp nat_rec_type do
    u = Level.param(:u)

    elab!(
      forall :a, Theoria.Syntax.sort(u) do
        arrow(
          var(:a),
          arrow(
            arrow(const(:Nat), arrow(var(:a), var(:a))),
            arrow(const(:Nat), var(:a))
          )
        )
      end
    )
  end

  defp nat_ind_type do
    u = Level.param(:u)

    elab!(
      forall :motive, arrow(const(:Nat), Theoria.Syntax.sort(u)) do
        arrow(
          call(var(:motive), const(:zero)),
          arrow(
            forall :n, const(:Nat) do
              arrow(
                call(var(:motive), var(:n)),
                call(var(:motive), call(const(:succ), var(:n)))
              )
            end,
            forall :n, const(:Nat) do
              call(var(:motive), var(:n))
            end
          )
        )
      end
    )
  end

  defp nat_add_type do
    elab!(arrow(const(:Nat), arrow(const(:Nat), const(:Nat))))
  end

  defp nat_add_value do
    elab!(
      lam :m, const(:Nat) do
        lam :n, const(:Nat) do
          call(
            const(:nat_rec, [1]),
            const(:Nat),
            var(:n),
            lam :_pred, const(:Nat) do
              lam :acc, const(:Nat) do
                call(const(:succ), var(:acc))
              end
            end,
            var(:m)
          )
        end
      end
    )
  end
end
