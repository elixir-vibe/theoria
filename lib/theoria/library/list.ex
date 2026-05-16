defmodule Theoria.Library.List do
  @moduledoc """
  Initial polymorphic list declarations and primitive recursion.
  """

  alias Theoria.Env
  alias Theoria.Kernel
  alias Theoria.Library.Nat

  import Theoria.DSL, except: [type: 1]

  @doc "Extends an environment with list declarations. Requires Nat declarations."
  def extend(%Env{} = env) do
    with {:ok, env} <- Kernel.add_constant(env, :List, list_type()),
         {:ok, env} <- Kernel.add_constant(env, :list_nil, list_nil_type()),
         {:ok, env} <- Kernel.add_constant(env, :list_cons, list_cons_type()),
         {:ok, env} <- Kernel.add_constant(env, :list_rec, list_rec_type()) do
      Kernel.add_definition(env, :list_length, list_length_type(), list_length_value())
    end
  end

  @doc "Returns a new Nat environment extended with list declarations."
  def env do
    with {:ok, env} <- Nat.env() do
      extend(env)
    end
  end

  defp list_type do
    elab!(
      forall :a, Theoria.DSL.type(0) do
        Theoria.DSL.type(0)
      end
    )
  end

  defp list_nil_type do
    elab!(
      forall :a, Theoria.DSL.type(0) do
        call(const(:List), var(:a))
      end
    )
  end

  defp list_cons_type do
    elab!(
      forall :a, Theoria.DSL.type(0) do
        arrow(
          var(:a),
          arrow(call(const(:List), var(:a)), call(const(:List), var(:a)))
        )
      end
    )
  end

  defp list_rec_type do
    elab!(
      forall :a, Theoria.DSL.type(0) do
        forall :b, Theoria.DSL.type(0) do
          arrow(
            var(:b),
            arrow(
              arrow(var(:a), arrow(call(const(:List), var(:a)), arrow(var(:b), var(:b)))),
              arrow(call(const(:List), var(:a)), var(:b))
            )
          )
        end
      end
    )
  end

  defp list_length_type do
    elab!(
      forall :a, Theoria.DSL.type(0) do
        arrow(call(const(:List), var(:a)), const(:Nat))
      end
    )
  end

  defp list_length_value do
    elab!(
      lam :a, Theoria.DSL.type(0) do
        lam :xs, call(const(:List), var(:a)) do
          call(const(:list_rec), [
            var(:a),
            const(:Nat),
            const(:zero),
            lam :_head, var(:a) do
              lam :_tail, call(const(:List), var(:a)) do
                lam :acc, const(:Nat) do
                  call(const(:succ), var(:acc))
                end
              end
            end,
            var(:xs)
          ])
        end
      end
    )
  end
end
