defmodule Theoria.Library.Bool.Theorems do
  @moduledoc """
  Theorem corpus for `Theoria.Library.Bool`.

  These proofs document the initial boolean declarations and computation rules
  accepted by definitional equality.
  """

  use Theoria.DSL

  theorem :true_is_bool do
    type do
      term do
        bool()
      end
    end

    proof do
      term do
        bool_true()
      end
    end
  end

  theorem :false_is_bool do
    type do
      term do
        bool()
      end
    end

    proof do
      term do
        bool_false()
      end
    end
  end

  theorem :bool_not_is_function do
    type do
      term do
        bool() ~> bool()
      end
    end

    proof do
      term do
        const(:bool_not)
      end
    end
  end

  theorem :bool_not_true do
    type do
      term do
        eq(bool(), bool_not(bool_true()), bool_false())
      end
    end

    proof do
      term do
        refl(bool_false())
      end
    end
  end

  theorem :bool_not_false do
    type do
      term do
        eq(bool(), bool_not(bool_false()), bool_true())
      end
    end

    proof do
      term do
        refl(bool_true())
      end
    end
  end

  theorem :bool_and_true_true do
    type do
      term do
        eq(bool(), bool_and(bool_true(), bool_true()), bool_true())
      end
    end

    proof do
      term do
        refl(bool_true())
      end
    end
  end

  theorem :bool_and_false_true do
    type do
      term do
        eq(bool(), bool_and(bool_false(), bool_true()), bool_false())
      end
    end

    proof do
      term do
        refl(bool_false())
      end
    end
  end

  theorem :bool_and_true_false do
    type do
      term do
        eq(bool(), bool_and(bool_true(), bool_false()), bool_false())
      end
    end

    proof do
      term do
        refl(bool_false())
      end
    end
  end

  theorem :bool_and_false_false do
    type do
      term do
        eq(bool(), bool_and(bool_false(), bool_false()), bool_false())
      end
    end

    proof do
      term do
        refl(bool_false())
      end
    end
  end

  theorem :bool_or_true_false do
    type do
      term do
        eq(bool(), bool_or(bool_true(), bool_false()), bool_true())
      end
    end

    proof do
      term do
        refl(bool_true())
      end
    end
  end

  theorem :bool_or_false_false do
    type do
      term do
        eq(bool(), bool_or(bool_false(), bool_false()), bool_false())
      end
    end

    proof do
      term do
        refl(bool_false())
      end
    end
  end

  theorem :bool_or_false_true do
    type do
      term do
        eq(bool(), bool_or(bool_false(), bool_true()), bool_true())
      end
    end

    proof do
      term do
        refl(bool_true())
      end
    end
  end

  theorem :bool_or_true_true do
    type do
      term do
        eq(bool(), bool_or(bool_true(), bool_true()), bool_true())
      end
    end

    proof do
      term do
        refl(bool_true())
      end
    end
  end

  theorem :bool_and_true_left do
    type do
      term do
        forall :b, bool() do
          eq(bool(), bool_and(bool_true(), b), b)
        end
      end
    end

    proof do
      term do
        lam :b, bool() do
          refl(b)
        end
      end
    end
  end

  theorem :bool_or_false_left do
    type do
      term do
        forall :b, bool() do
          eq(bool(), bool_or(bool_false(), b), b)
        end
      end
    end

    proof do
      term do
        lam :b, bool() do
          refl(b)
        end
      end
    end
  end
end
