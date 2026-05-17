defmodule Theoria.Library.Vec.Theorems do
  @moduledoc "Theorem corpus for `Theoria.Library.Vec`."

  use Theoria.DSL

  theorem :vec_nil_is_vec do
    type do
      term do
        forall :a, type(0) do
          vec(a, zero)
        end
      end
    end

    proof do
      term do
        vec_nil
      end
    end
  end

  theorem :vec_cons_is_function do
    type do
      term do
        forall :a, type(0) do
          a
          ~> forall :n, nat() do
            vec(a, n) ~> vec(a, succ(n))
          end
        end
      end
    end

    proof do
      term do
        vec_cons
      end
    end
  end

  theorem :vec_ind_nil_nat do
    type do
      term do
        eq(
          nat(),
          vec_ind(
            nat(),
            lam :n, nat() do
              lam :xs, vec(nat(), n) do
                nat()
              end
            end,
            zero,
            lam :head, nat() do
              lam :n, nat() do
                lam :tail, vec(nat(), n) do
                  lam :ih, nat() do
                    succ(ih)
                  end
                end
              end
            end,
            zero,
            vec_nil(nat())
          ),
          zero
        )
      end
    end

    proof do
      term do
        refl(zero)
      end
    end
  end

  theorem :vec_ind_cons_nat do
    type do
      term do
        eq(
          nat(),
          vec_ind(
            nat(),
            lam :n, nat() do
              lam :xs, vec(nat(), n) do
                nat()
              end
            end,
            zero,
            lam :head, nat() do
              lam :n, nat() do
                lam :tail, vec(nat(), n) do
                  lam :ih, nat() do
                    succ(ih)
                  end
                end
              end
            end,
            succ(zero),
            vec_cons(nat(), zero, zero, vec_nil(nat()))
          ),
          succ(zero)
        )
      end
    end

    proof do
      term do
        refl(succ(zero))
      end
    end
  end
end
