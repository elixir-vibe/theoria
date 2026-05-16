defmodule Theoria.Library.List do
  @moduledoc """
  Initial polymorphic list declarations and primitive recursion.
  """

  alias Theoria.Env
  alias Theoria.Inductive.Generate
  alias Theoria.Inductive.Spec
  alias Theoria.Kernel
  alias Theoria.Level
  alias Theoria.Library.Nat

  import Theoria.DSL, except: [type: 1]

  @doc "Extends an environment with list declarations. Requires Nat declarations."
  def extend(%Env{} = env) do
    with {:ok, env} <- Kernel.add_inductive(env, inductive_spec()) do
      Kernel.add_definition(env, :list_length, list_length_type(), list_length_value(), [:u])
    end
  end

  @doc "Returns a new Nat environment extended with list declarations."
  def env do
    with {:ok, env} <- Nat.env() do
      extend(env)
    end
  end

  @doc "Returns the inductive specification described by this library."
  def inductive_spec do
    spec =
      :List
      |> Spec.new(list_type(), universe_params: [:u, :v])
      |> Spec.constructor(:list_nil, list_nil_type())
      |> Spec.constructor(:list_cons, list_cons_type())

    %Spec{spec | recursors: Generate.list_eliminators(spec)}
  end

  defp list_type do
    u = Level.param(:u)

    elab!(
      forall :a, Theoria.Syntax.sort(u) do
        Theoria.Syntax.sort(u)
      end
    )
  end

  defp list_nil_type do
    u = Level.param(:u)

    elab!(
      forall :a, Theoria.Syntax.sort(u) do
        call(const(:List, [u]), var(:a))
      end
    )
  end

  defp list_cons_type do
    u = Level.param(:u)

    elab!(
      forall :a, Theoria.Syntax.sort(u) do
        arrow(
          var(:a),
          arrow(call(const(:List, [u]), var(:a)), call(const(:List, [u]), var(:a)))
        )
      end
    )
  end

  defp list_length_type do
    u = Level.param(:u)

    elab!(
      forall :a, Theoria.Syntax.sort(u) do
        arrow(call(const(:List, [u]), var(:a)), const(:Nat))
      end
    )
  end

  defp list_length_value do
    u = Level.param(:u)

    elab!(
      lam :a, Theoria.Syntax.sort(u) do
        lam :xs, call(const(:List, [u]), var(:a)) do
          call(const(:list_rec, [u, 1]), [
            var(:a),
            const(:Nat),
            const(:zero),
            lam :_head, var(:a) do
              lam :_tail, call(const(:List, [u]), var(:a)) do
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
