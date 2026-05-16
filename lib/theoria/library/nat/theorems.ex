defmodule Theoria.Library.Nat.Theorems do
  @moduledoc """
  Theorem corpus for `Theoria.Library.Nat`.

  These proofs document the initial natural number declarations, primitive
  recursion, and addition computations that reduce by reflexivity.
  """

  use Theoria.DSL

  theorem :zero_is_nat do
    type do
      const(:Nat)
    end

    proof do
      const(:zero)
    end
  end

  theorem :succ_is_function do
    type do
      arrow(const(:Nat), const(:Nat))
    end

    proof do
      const(:succ)
    end
  end

  theorem :nat_add_zero_left do
    type do
      forall :n, const(:Nat) do
        eq(const(:Nat), call(const(:nat_add), const(:zero), var(:n)), var(:n))
      end
    end

    proof do
      lam :n, const(:Nat) do
        refl(var(:n))
      end
    end
  end

  theorem :nat_add_one_left do
    type do
      forall :n, const(:Nat) do
        eq(
          const(:Nat),
          call(const(:nat_add), call(const(:succ), const(:zero)), var(:n)),
          call(const(:succ), var(:n))
        )
      end
    end

    proof do
      lam :n, const(:Nat) do
        refl(call(const(:succ), var(:n)))
      end
    end
  end

  theorem :nat_add_one_zero do
    type do
      eq(
        const(:Nat),
        call(const(:nat_add), call(const(:succ), const(:zero)), const(:zero)),
        call(const(:succ), const(:zero))
      )
    end

    proof do
      refl(call(const(:succ), const(:zero)))
    end
  end

  theorem :nat_add_two_left do
    type do
      forall :n, const(:Nat) do
        eq(
          const(:Nat),
          call(
            const(:nat_add),
            call(const(:succ), call(const(:succ), const(:zero))),
            var(:n)
          ),
          call(const(:succ), call(const(:succ), var(:n)))
        )
      end
    end

    proof do
      lam :n, const(:Nat) do
        refl(call(const(:succ), call(const(:succ), var(:n))))
      end
    end
  end

  theorem :nat_add_two_zero do
    type do
      eq(
        const(:Nat),
        call(
          const(:nat_add),
          call(const(:succ), call(const(:succ), const(:zero))),
          const(:zero)
        ),
        call(const(:succ), call(const(:succ), const(:zero)))
      )
    end

    proof do
      refl(call(const(:succ), call(const(:succ), const(:zero))))
    end
  end
end
