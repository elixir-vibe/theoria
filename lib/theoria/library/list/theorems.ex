defmodule Theoria.Library.List.Theorems do
  @moduledoc """
  Theorem corpus for `Theoria.Library.List`.

  These proofs document polymorphic list constructors and the first length
  computation over the standard Nat-backed list environment.
  """

  use Theoria.DSL

  theorem :list_nil_is_list do
    type do
      forall :a, type(0) do
        call(const(:List), var(:a))
      end
    end

    proof do
      const(:list_nil)
    end
  end

  theorem :list_cons_is_function do
    type do
      forall :a, type(0) do
        arrow(
          var(:a),
          arrow(call(const(:List), var(:a)), call(const(:List), var(:a)))
        )
      end
    end

    proof do
      const(:list_cons)
    end
  end

  theorem :list_length_nil do
    type do
      forall :a, type(0) do
        eq(
          const(:Nat),
          call(const(:list_length), var(:a), call(const(:list_nil), var(:a))),
          const(:zero)
        )
      end
    end

    proof do
      lam :a, type(0) do
        refl(const(:zero))
      end
    end
  end

  theorem :list_length_singleton do
    type do
      forall :a, type(0) do
        forall :x, var(:a) do
          eq(
            const(:Nat),
            call(
              const(:list_length),
              var(:a),
              call(
                const(:list_cons),
                var(:a),
                var(:x),
                call(const(:list_nil), var(:a))
              )
            ),
            call(const(:succ), const(:zero))
          )
        end
      end
    end

    proof do
      lam :a, type(0) do
        lam :x, var(:a) do
          refl(call(const(:succ), const(:zero)))
        end
      end
    end
  end

  theorem :list_length_cons_nil do
    type do
      forall :a, type(0) do
        forall :x, var(:a) do
          eq(
            const(:Nat),
            call(const(:list_rec), [
              var(:a),
              const(:Nat),
              const(:zero),
              lam :_head, var(:a) do
                lam :_tail, call(const(:List), var(:a)) do
                  lam :acc, const(:Nat) do
                    call(const(:succ), var(:acc))
                  end
                end
              end,
              call(
                const(:list_cons),
                var(:a),
                var(:x),
                call(const(:list_nil), var(:a))
              )
            ]),
            call(const(:succ), const(:zero))
          )
        end
      end
    end

    proof do
      lam :a, type(0) do
        lam :x, var(:a) do
          refl(call(const(:succ), const(:zero)))
        end
      end
    end
  end

  theorem :list_length_cons do
    type do
      forall :a, type(0) do
        forall :x, var(:a) do
          forall :xs, call(const(:List), var(:a)) do
            eq(
              const(:Nat),
              call(
                const(:list_length),
                var(:a),
                call(const(:list_cons), var(:a), var(:x), var(:xs))
              ),
              call(const(:succ), call(const(:list_length), var(:a), var(:xs)))
            )
          end
        end
      end
    end

    proof do
      lam :a, type(0) do
        lam :x, var(:a) do
          lam :xs, call(const(:List), var(:a)) do
            refl(call(const(:succ), call(const(:list_length), var(:a), var(:xs))))
          end
        end
      end
    end
  end

  theorem :list_length_two do
    type do
      forall :a, type(0) do
        forall :x, var(:a) do
          forall :y, var(:a) do
            eq(
              const(:Nat),
              call(
                const(:list_length),
                var(:a),
                call(
                  const(:list_cons),
                  var(:a),
                  var(:x),
                  call(
                    const(:list_cons),
                    var(:a),
                    var(:y),
                    call(const(:list_nil), var(:a))
                  )
                )
              ),
              call(const(:succ), call(const(:succ), const(:zero)))
            )
          end
        end
      end
    end

    proof do
      lam :a, type(0) do
        lam :x, var(:a) do
          lam :y, var(:a) do
            refl(call(const(:succ), call(const(:succ), const(:zero))))
          end
        end
      end
    end
  end
end
