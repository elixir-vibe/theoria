defmodule Theoria.Library.Logic.Theorems do
  @moduledoc """
  Theorem corpus for `Theoria.Library.Logic`.

  These proofs cover the initial logical declarations for implication-like
  function types, false elimination, negation, and conjunction. They exercise
  the public theorem DSL against both `Theoria.Library.Logic.env/0` and the
  standard `Theoria.Prelude.env/0`.
  """

  use Theoria.DSL

  theorem :identity do
    type do
      term do
        forall :p, prop() do
          p ~> p
        end
      end
    end

    proof do
      term do
        lam :p, prop() do
          lam :hp, p do
            hp
          end
        end
      end
    end
  end

  theorem :const do
    type do
      term do
        forall :p, prop() do
          forall :q, prop() do
            forall :hp, p do
              forall :_hq, q do
                p
              end
            end
          end
        end
      end
    end

    proof do
      term do
        lam :p, prop() do
          lam :q, prop() do
            lam :hp, p do
              lam :_hq, q do
                hp
              end
            end
          end
        end
      end
    end
  end

  theorem :false_elim_eta do
    type do
      term do
        forall :p, prop() do
          false_prop() ~> p
        end
      end
    end

    proof do
      term do
        lam :p, prop() do
          lam :hfalse, const(:False) do
            false_elim(p, hfalse)
          end
        end
      end
    end
  end

  theorem :double_negation_intro do
    type do
      term do
        forall :p, prop() do
          forall :hp, p do
            neg(neg(p))
          end
        end
      end
    end

    proof do
      term do
        lam :p, prop() do
          lam :hp, p do
            lam :hnp, neg(p) do
              app(hnp, hp)
            end
          end
        end
      end
    end
  end

  theorem :and_left_eta do
    type do
      term do
        forall :p, prop() do
          forall :q, prop() do
            forall :h, conj(p, q) do
              p
            end
          end
        end
      end
    end

    proof do
      term do
        lam :p, prop() do
          lam :q, prop() do
            lam :h, conj(p, q) do
              and_left(p, q, h)
            end
          end
        end
      end
    end
  end

  theorem :and_right_eta do
    type do
      term do
        forall :p, prop() do
          forall :q, prop() do
            forall :h, conj(p, q) do
              q
            end
          end
        end
      end
    end

    proof do
      term do
        lam :p, prop() do
          lam :q, prop() do
            lam :h, conj(p, q) do
              and_right(p, q, h)
            end
          end
        end
      end
    end
  end

  theorem :and_comm do
    type do
      term do
        forall :p, prop() do
          forall :q, prop() do
            forall :h, conj(p, q) do
              conj(q, p)
            end
          end
        end
      end
    end

    proof do
      term do
        lam :p, prop() do
          lam :q, prop() do
            lam :h, conj(p, q) do
              and_intro(q, p, and_right(p, q, h), and_left(p, q, h))
            end
          end
        end
      end
    end
  end

  theorem :and_intro_eta do
    type do
      term do
        forall :p, prop() do
          forall :q, prop() do
            forall :hp, p do
              forall :hq, q do
                conj(p, q)
              end
            end
          end
        end
      end
    end

    proof do
      term do
        lam :p, prop() do
          lam :q, prop() do
            lam :hp, p do
              lam :hq, q do
                and_intro(p, q, hp, hq)
              end
            end
          end
        end
      end
    end
  end

  theorem :not_false do
    type do
      term do
        neg(const(:False))
      end
    end

    proof do
      term do
        lam :hfalse, const(:False) do
          hfalse
        end
      end
    end
  end

  theorem :contradiction do
    type do
      term do
        forall :p, prop() do
          forall :hp, p do
            forall :hnp, neg(p) do
              const(:False)
            end
          end
        end
      end
    end

    proof do
      term do
        lam :p, prop() do
          lam :hp, p do
            lam :hnp, neg(p) do
              app(hnp, hp)
            end
          end
        end
      end
    end
  end

  theorem :and_assoc_left do
    type do
      term do
        forall :p, prop() do
          forall :q, prop() do
            forall :r, prop() do
              forall :h, conj(conj(p, q), r) do
                conj(p, conj(q, r))
              end
            end
          end
        end
      end
    end

    proof do
      term do
        lam :p, prop() do
          lam :q, prop() do
            lam :r, prop() do
              lam :h, conj(conj(p, q), r) do
                and_intro(
                  p,
                  conj(q, r),
                  and_left(p, q, and_left(conj(p, q), r, h)),
                  and_intro(
                    q,
                    r,
                    and_right(p, q, and_left(conj(p, q), r, h)),
                    and_right(conj(p, q), r, h)
                  )
                )
              end
            end
          end
        end
      end
    end
  end

  theorem :and_assoc_right do
    type do
      term do
        forall :p, prop() do
          forall :q, prop() do
            forall :r, prop() do
              forall :h, conj(p, conj(q, r)) do
                conj(conj(p, q), r)
              end
            end
          end
        end
      end
    end

    proof do
      term do
        lam :p, prop() do
          lam :q, prop() do
            lam :r, prop() do
              lam :h, conj(p, conj(q, r)) do
                and_intro(
                  conj(p, q),
                  r,
                  and_intro(
                    p,
                    q,
                    and_left(p, conj(q, r), h),
                    and_left(q, r, and_right(p, conj(q, r), h))
                  ),
                  and_right(q, r, and_right(p, conj(q, r), h))
                )
              end
            end
          end
        end
      end
    end
  end
end
