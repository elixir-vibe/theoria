defmodule Theoria.Library.Bool do
  @moduledoc """
  Initial computational boolean declarations.

  This library introduces booleans as ordinary data in `Type 0`, distinct from
  the logical propositions `True` and `False` in `Theoria.Library.Logic`.
  """

  alias Theoria.Env
  alias Theoria.Kernel
  alias Theoria.Level

  import Theoria.DSL, except: [type: 1]

  @doc "The core universe for `Type 0`."
  def type, do: Theoria.Term.sort(1)

  @doc "Extends an environment with boolean declarations."
  def extend(%Env{} = env) do
    with {:ok, env} <- Kernel.add_constant(env, :Bool, type()),
         {:ok, env} <- Kernel.add_constant(env, true, Theoria.Term.const(:Bool)),
         {:ok, env} <- Kernel.add_constant(env, false, Theoria.Term.const(:Bool)),
         {:ok, env} <- Kernel.add_constant(env, :bool_rec, bool_rec_type(), [:u]),
         {:ok, env} <- Kernel.add_constant(env, :bool_ind, bool_ind_type(), [:u]),
         {:ok, env} <- Kernel.add_definition(env, :bool_not, bool_not_type(), bool_not_value()),
         {:ok, env} <- Kernel.add_definition(env, :bool_and, bool_binary_type(), bool_and_value()) do
      Kernel.add_definition(env, :bool_or, bool_binary_type(), bool_or_value())
    end
  end

  @doc "Returns a new environment extended with boolean declarations."
  def env do
    extend(Env.new())
  end

  defp bool_rec_type do
    u = Level.param(:u)

    elab!(
      forall :a, Theoria.Syntax.sort(u) do
        arrow(
          var(:a),
          arrow(
            var(:a),
            arrow(const(:Bool), var(:a))
          )
        )
      end
    )
  end

  defp bool_ind_type do
    u = Level.param(:u)

    elab!(
      forall :motive, arrow(const(:Bool), Theoria.Syntax.sort(u)) do
        arrow(
          call(var(:motive), const(true)),
          arrow(
            call(var(:motive), const(false)),
            forall :b, const(:Bool) do
              call(var(:motive), var(:b))
            end
          )
        )
      end
    )
  end

  defp bool_not_type do
    elab!(arrow(const(:Bool), const(:Bool)))
  end

  defp bool_not_value do
    elab!(
      lam :b, const(:Bool) do
        term do
          bool_rec(const(:Bool), false, true, b)
        end
      end
    )
  end

  defp bool_binary_type do
    elab!(
      arrow(
        const(:Bool),
        arrow(const(:Bool), const(:Bool))
      )
    )
  end

  defp bool_and_value do
    elab!(
      lam :a, const(:Bool) do
        lam :b, const(:Bool) do
          term do
            bool_rec(const(:Bool), b, false, a)
          end
        end
      end
    )
  end

  defp bool_or_value do
    elab!(
      lam :a, const(:Bool) do
        lam :b, const(:Bool) do
          term do
            bool_rec(const(:Bool), true, b, a)
          end
        end
      end
    )
  end
end
