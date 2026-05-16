defmodule Theoria.Library.List.Theorems do
  @moduledoc """
  Theorem corpus for `Theoria.Library.List`.

  These proofs document polymorphic list constructors and the first length
  computation over the standard Nat-backed list environment.
  """

  use Theoria.DSL

  theorem :list_nil_is_list do
    type do
      term do
        forall :a, type(0) do
          list(a)
        end
      end
    end

    proof do
      term do
        list_nil
      end
    end
  end

  theorem :list_cons_is_function do
    type do
      term do
        forall :a, type(0) do
          a ~> (list(a) ~> list(a))
        end
      end
    end

    proof do
      term do
        list_cons
      end
    end
  end

  theorem :list_length_nil do
    type do
      term do
        forall :a, type(0) do
          eq(nat(), list_length(a, list_nil(a)), zero)
        end
      end
    end

    proof do
      term do
        lam :a, type(0) do
          refl(zero)
        end
      end
    end
  end

  theorem :list_length_singleton do
    type do
      term do
        forall :a, type(0) do
          forall :x, a do
            eq(nat(), list_length(a, list_cons(a, x, list_nil(a))), succ(zero))
          end
        end
      end
    end

    proof do
      term do
        lam :a, type(0) do
          lam :x, a do
            refl(succ(zero))
          end
        end
      end
    end
  end

  theorem :list_length_cons_nil do
    type do
      term do
        forall :a, type(0) do
          forall :x, a do
            eq(
              nat(),
              list_rec(
                a,
                nat(),
                zero,
                lam :_head, a do
                  lam :_tail, list(a) do
                    lam :acc, nat() do
                      succ(acc)
                    end
                  end
                end,
                list_cons(a, x, list_nil(a))
              ),
              succ(zero)
            )
          end
        end
      end
    end

    proof do
      term do
        lam :a, type(0) do
          lam :x, a do
            refl(succ(zero))
          end
        end
      end
    end
  end

  theorem :list_length_cons do
    type do
      term do
        forall :a, type(0) do
          forall :x, a do
            forall :xs, list(a) do
              eq(nat(), list_length(a, list_cons(a, x, xs)), succ(list_length(a, xs)))
            end
          end
        end
      end
    end

    proof do
      term do
        lam :a, type(0) do
          lam :x, a do
            lam :xs, list(a) do
              refl(succ(list_length(a, xs)))
            end
          end
        end
      end
    end
  end

  theorem :list_length_two do
    type do
      term do
        forall :a, type(0) do
          forall :x, a do
            forall :y, a do
              eq(
                nat(),
                list_length(a, list_cons(a, x, list_cons(a, y, list_nil(a)))),
                succ(succ(zero))
              )
            end
          end
        end
      end
    end

    proof do
      term do
        lam :a, type(0) do
          lam :x, a do
            lam :y, a do
              refl(succ(succ(zero)))
            end
          end
        end
      end
    end
  end
end
