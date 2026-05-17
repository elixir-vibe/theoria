defmodule Theoria.Library.Vec do
  @moduledoc "Length-indexed vectors."

  alias Theoria.Env
  alias Theoria.Inductive
  alias Theoria.Inductive.Spec
  alias Theoria.Kernel
  alias Theoria.Level
  alias Theoria.Library.Nat

  import Theoria.DSL, except: [type: 1]

  @doc "Extends an environment with Vec declarations. Requires Nat declarations."
  @spec extend(Env.t()) :: {:ok, Env.t()} | {:error, Theoria.Error.t()}
  def extend(%Env{} = env) do
    with {:ok, spec} <- Inductive.complete(inductive_spec()) do
      Kernel.add_inductive(env, spec)
    end
  end

  @doc "Returns a new Nat environment extended with Vec declarations."
  @spec env() :: {:ok, Env.t()} | {:error, Theoria.Error.t()}
  def env do
    with {:ok, env} <- Nat.env() do
      extend(env)
    end
  end

  @doc "Returns the inductive specification described by this library."
  @spec inductive_spec() :: Spec.t()
  def inductive_spec do
    u = Level.param(:u)

    :Vec
    |> Spec.new(vec_type(u), universe_params: [:u])
    |> Spec.parameter(:a, term(do: sort(^u)) |> elab!())
    |> Spec.index(:n, term(do: nat()) |> elab!())
    |> Spec.constructor(:vec_nil, vec_nil_type(u))
    |> Spec.constructor(:vec_cons, vec_cons_type(u))
  end

  defp vec_type(u) do
    term do
      forall :a, sort(^u) do
        nat() ~> sort(^u)
      end
    end
    |> elab!()
  end

  defp vec_nil_type(u) do
    term do
      forall :a, sort(^u) do
        app(app(const(:Vec, [^u]), a), zero)
      end
    end
    |> elab!()
  end

  defp vec_cons_type(u) do
    term do
      forall :a, sort(^u) do
        a
        ~> forall :n, nat() do
          app(app(const(:Vec, [^u]), a), n)
          ~> app(app(const(:Vec, [^u]), a), app(succ, n))
        end
      end
    end
    |> elab!()
  end
end
