defmodule Theoria.Library.List do
  @moduledoc """
  Initial polymorphic list declarations and primitive recursion.
  """

  alias Theoria.Env
  alias Theoria.Env.Reduction
  alias Theoria.Inductive
  alias Theoria.Inductive.{Constructor, Recursor, Spec}
  alias Theoria.Kernel
  alias Theoria.Level
  alias Theoria.Library.Nat

  import Theoria.DSL, except: [type: 1]

  @doc "Extends an environment with list declarations. Requires Nat declarations."
  def extend(%Env{} = env) do
    with {:ok, env} <- Inductive.install(env, inductive_spec()) do
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
    %Spec{
      name: :List,
      type: list_type(),
      universe_params: [:u, :v],
      constructors: [
        %Constructor{name: :list_nil, type: list_nil_type()},
        %Constructor{name: :list_cons, type: list_cons_type()}
      ],
      recursors: [
        %Recursor{name: :list_rec, type: list_rec_type(), reduction: %Reduction.ListRec{}},
        %Recursor{name: :list_ind, type: list_ind_type(), reduction: %Reduction.ListInd{}}
      ]
    }
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

  defp list_rec_type do
    u = Level.param(:u)
    v = Level.param(:v)

    elab!(
      forall :a, Theoria.Syntax.sort(u) do
        forall :b, Theoria.Syntax.sort(v) do
          arrow(
            var(:b),
            arrow(
              arrow(var(:a), arrow(call(const(:List, [u]), var(:a)), arrow(var(:b), var(:b)))),
              arrow(call(const(:List, [u]), var(:a)), var(:b))
            )
          )
        end
      end
    )
  end

  defp list_ind_type do
    u = Level.param(:u)
    v = Level.param(:v)

    elab!(
      forall :a, Theoria.Syntax.sort(u) do
        forall :motive, arrow(call(const(:List, [u]), var(:a)), Theoria.Syntax.sort(v)) do
          arrow(
            call(var(:motive), call(const(:list_nil, [u]), var(:a))),
            arrow(
              forall :x, var(:a) do
                forall :xs, call(const(:List, [u]), var(:a)) do
                  arrow(
                    call(var(:motive), var(:xs)),
                    call(
                      var(:motive),
                      call(const(:list_cons, [u]), [var(:a), var(:x), var(:xs)])
                    )
                  )
                end
              end,
              forall :xs, call(const(:List, [u]), var(:a)) do
                call(var(:motive), var(:xs))
              end
            )
          )
        end
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
