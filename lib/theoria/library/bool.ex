defmodule Theoria.Library.Bool do
  @moduledoc """
  Initial computational boolean declarations.

  This library introduces booleans as ordinary data in `Type 0`, distinct from
  the logical propositions `True` and `False` in `Theoria.Library.Logic`.
  """

  alias Theoria.Env
  alias Theoria.Kernel

  import Theoria.DSL, except: [type: 1]

  @doc "The core universe for `Type 0`."
  def type, do: Theoria.Term.sort(1)

  @doc "Extends an environment with boolean declarations."
  def extend(%Env{} = env) do
    with {:ok, env} <- Kernel.add_constant(env, :Bool, type()),
         {:ok, env} <- Kernel.add_constant(env, true, Theoria.Term.const(:Bool)),
         {:ok, env} <- Kernel.add_constant(env, false, Theoria.Term.const(:Bool)),
         {:ok, env} <- Kernel.add_constant(env, :bool_not, bool_not_type()),
         {:ok, env} <- Kernel.add_constant(env, :bool_and, bool_binary_type()) do
      Kernel.add_constant(env, :bool_or, bool_binary_type())
    end
  end

  @doc "Returns a new environment extended with boolean declarations."
  def env do
    extend(Env.new())
  end

  defp bool_not_type do
    elab!(arrow(const(:Bool), const(:Bool)))
  end

  defp bool_binary_type do
    elab!(
      arrow(
        const(:Bool),
        arrow(const(:Bool), const(:Bool))
      )
    )
  end
end
