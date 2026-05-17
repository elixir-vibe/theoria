defmodule Theoria.Library.Equality.Theorems do
  @moduledoc "Theorem corpus for primitive propositional equality."

  use Theoria.DSL

  theorem :eq_refl do
    type do
      term do
        forall :a, type(0) do
          forall :x, a do
            eq(a, x, x)
          end
        end
      end
    end

    proof do
      term do
        lam :a, type(0) do
          lam :x, a do
            refl(x)
          end
        end
      end
    end
  end

  theorem :eq_symm do
    type do
      term do
        forall :a, type(0) do
          forall :x, a do
            forall :y, a do
              eq(a, x, y) ~> eq(a, y, x)
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
              lam :h, eq(a, x, y) do
                eq_rec(
                  a,
                  lam :z, a do
                    eq(a, z, x)
                  end,
                  refl(x),
                  h
                )
              end
            end
          end
        end
      end
    end
  end

  theorem :eq_trans do
    type do
      term do
        forall :a, type(0) do
          forall :x, a do
            forall :y, a do
              forall :z, a do
                eq(a, x, y) ~> (eq(a, y, z) ~> eq(a, x, z))
              end
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
              lam :z, a do
                lam :hxy, eq(a, x, y) do
                  lam :hyz, eq(a, y, z) do
                    eq_rec(
                      a,
                      lam :w, a do
                        eq(a, x, w)
                      end,
                      hxy,
                      hyz
                    )
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  theorem :eq_congr do
    type do
      term do
        forall :a, type(0) do
          forall :b, type(0) do
            forall :f, a ~> b do
              forall :x, a do
                forall :y, a do
                  eq(a, x, y) ~> eq(b, app(f, x), app(f, y))
                end
              end
            end
          end
        end
      end
    end

    proof do
      term do
        lam :a, type(0) do
          lam :b, type(0) do
            lam :f, a ~> b do
              lam :x, a do
                lam :y, a do
                  lam :h, eq(a, x, y) do
                    eq_rec(
                      a,
                      lam :z, a do
                        eq(b, app(f, x), app(f, z))
                      end,
                      refl(app(f, x)),
                      h
                    )
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
