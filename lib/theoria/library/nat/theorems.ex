defmodule Theoria.Library.Nat.Theorems do
  @moduledoc """
  Theorem corpus for `Theoria.Library.Nat`.

  These proofs document the initial natural number declarations, primitive
  recursion, and addition computations that reduce by reflexivity.
  """

  use Theoria.DSL

  theorem :zero_is_nat do
    type do
      term do
        const(:Nat)
      end
    end

    proof do
      term do
        zero
      end
    end
  end

  theorem :succ_is_function do
    type do
      term do
        arrow(const(:Nat), const(:Nat))
      end
    end

    proof do
      term do
        succ
      end
    end
  end

  theorem :nat_add_zero_left do
    type do
      term do
        forall :n, const(:Nat) do
          eq(const(:Nat), nat_add(zero, n), n)
        end
      end
    end

    proof do
      term do
        lam :n, const(:Nat) do
          refl(n)
        end
      end
    end
  end

  theorem :nat_add_one_left do
    type do
      term do
        forall :n, const(:Nat) do
          eq(const(:Nat), nat_add(succ(zero), n), succ(n))
        end
      end
    end

    proof do
      term do
        lam :n, const(:Nat) do
          refl(succ(n))
        end
      end
    end
  end

  theorem :nat_add_one_zero do
    type do
      term do
        eq(const(:Nat), nat_add(succ(zero), zero), succ(zero))
      end
    end

    proof do
      term do
        refl(succ(zero))
      end
    end
  end

  theorem :nat_add_two_left do
    type do
      term do
        forall :n, const(:Nat) do
          eq(const(:Nat), nat_add(succ(succ(zero)), n), succ(succ(n)))
        end
      end
    end

    proof do
      term do
        lam :n, const(:Nat) do
          refl(succ(succ(n)))
        end
      end
    end
  end

  theorem :nat_add_two_zero do
    type do
      term do
        eq(const(:Nat), nat_add(succ(succ(zero)), zero), succ(succ(zero)))
      end
    end

    proof do
      term do
        refl(succ(succ(zero)))
      end
    end
  end
end
