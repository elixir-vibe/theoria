defmodule Theoria.Rewrite.Proof.Check do
  @moduledoc false

  alias Theoria.Env
  alias Theoria.Kernel
  alias Theoria.Rewrite.Step
  alias Theoria.Term

  @spec lifted(Env.t(), Term.t(), Term.t(), Step.t()) ::
          {:ok, Term.t()} | {:error, :kernel_rejected}
  def lifted(%Env{} = env, type, candidate, %Step{} = step) do
    case Kernel.check(env, candidate, Term.eq(type, step.before, step.after)) do
      :ok -> {:ok, candidate}
      {:error, _reason} -> {:error, :kernel_rejected}
    end
  end
end
