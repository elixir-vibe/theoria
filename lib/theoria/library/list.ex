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
    with {:ok, env} <- Kernel.add_inductive(env, inductive_spec()),
         {:ok, env} <-
           Kernel.add_definition(env, :list_length, list_length_type(), list_length_value(), [:u]) do
      Kernel.add_definition(env, :list_append, list_append_type(), list_append_value(), [:u])
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
      |> Spec.parameter(:a, term(do: sort(u)) |> elab!())
      |> Spec.constructor(:list_nil, list_nil_type())
      |> Spec.constructor(:list_cons, list_cons_type())

    %Spec{spec | recursors: Generate.eliminators!(spec)}
  end

  defp list_type do
    u = Level.param(:u)
    sort_u = Theoria.Syntax.sort(u)

    elab!(
      forall :a, sort_u do
        sort_u
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
    a = var(:a)
    list_a = call(const(:List, [u]), a)

    elab!(
      forall :a, Theoria.Syntax.sort(u) do
        arrow(a, arrow(list_a, list_a))
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

  defp list_append_type do
    u = Level.param(:u)
    a = var(:a)
    list_a = call(const(:List, [u]), a)

    elab!(
      forall :a, Theoria.Syntax.sort(u) do
        arrow(list_a, arrow(list_a, list_a))
      end
    )
  end

  defp list_append_value do
    u = Level.param(:u)
    a = var(:a)
    left = var(:left)
    right = var(:right)
    head = var(:head)
    acc = var(:acc)
    list_a = call(const(:List, [u]), a)

    elab!(
      lam :a, Theoria.Syntax.sort(u) do
        lam :left, list_a do
          lam :right, list_a do
            call(const(:list_rec, [u, u]), [
              a,
              list_a,
              right,
              lam :head, a do
                lam :_tail, list_a do
                  lam :acc, list_a do
                    call(const(:list_cons, [u]), a, head, acc)
                  end
                end
              end,
              left
            ])
          end
        end
      end
    )
  end

  defp list_length_value do
    u = Level.param(:u)
    a = var(:a)
    xs = var(:xs)
    acc = var(:acc)
    list_a = call(const(:List, [u]), a)

    elab!(
      lam :a, Theoria.Syntax.sort(u) do
        lam :xs, list_a do
          call(const(:list_rec, [u, 1]), [
            a,
            const(:Nat),
            const(:zero),
            lam :_head, a do
              lam :_tail, list_a do
                lam :acc, const(:Nat) do
                  call(const(:succ), acc)
                end
              end
            end,
            xs
          ])
        end
      end
    )
  end
end
