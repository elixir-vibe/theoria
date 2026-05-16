defmodule Theoria.Library.Bool.Theorems do
  @moduledoc """
  Theorem corpus for `Theoria.Library.Bool`.

  These proofs document the initial boolean declarations and computation rules
  accepted by definitional equality.
  """

  use Theoria.DSL

  theorem :true_is_bool do
    type do
      const(:Bool)
    end

    proof do
      const(true)
    end
  end

  theorem :false_is_bool do
    type do
      const(:Bool)
    end

    proof do
      const(false)
    end
  end

  theorem :bool_not_is_function do
    type do
      arrow(const(:Bool), const(:Bool))
    end

    proof do
      const(:bool_not)
    end
  end

  theorem :bool_not_true do
    type do
      eq(const(:Bool), call(const(:bool_not), const(true)), const(false))
    end

    proof do
      refl(const(false))
    end
  end

  theorem :bool_not_false do
    type do
      eq(const(:Bool), call(const(:bool_not), const(false)), const(true))
    end

    proof do
      refl(const(true))
    end
  end

  theorem :bool_and_true_true do
    type do
      eq(const(:Bool), call(const(:bool_and), const(true), const(true)), const(true))
    end

    proof do
      refl(const(true))
    end
  end

  theorem :bool_and_false_true do
    type do
      eq(const(:Bool), call(const(:bool_and), const(false), const(true)), const(false))
    end

    proof do
      refl(const(false))
    end
  end

  theorem :bool_and_true_false do
    type do
      eq(const(:Bool), call(const(:bool_and), const(true), const(false)), const(false))
    end

    proof do
      refl(const(false))
    end
  end

  theorem :bool_and_false_false do
    type do
      eq(const(:Bool), call(const(:bool_and), const(false), const(false)), const(false))
    end

    proof do
      refl(const(false))
    end
  end

  theorem :bool_or_true_false do
    type do
      eq(const(:Bool), call(const(:bool_or), const(true), const(false)), const(true))
    end

    proof do
      refl(const(true))
    end
  end

  theorem :bool_or_false_false do
    type do
      eq(const(:Bool), call(const(:bool_or), const(false), const(false)), const(false))
    end

    proof do
      refl(const(false))
    end
  end

  theorem :bool_or_false_true do
    type do
      eq(const(:Bool), call(const(:bool_or), const(false), const(true)), const(true))
    end

    proof do
      refl(const(true))
    end
  end

  theorem :bool_or_true_true do
    type do
      eq(const(:Bool), call(const(:bool_or), const(true), const(true)), const(true))
    end

    proof do
      refl(const(true))
    end
  end

  theorem :bool_and_true_left do
    type do
      forall :b, const(:Bool) do
        eq(const(:Bool), call(const(:bool_and), const(true), var(:b)), var(:b))
      end
    end

    proof do
      lam :b, const(:Bool) do
        refl(var(:b))
      end
    end
  end

  theorem :bool_or_false_left do
    type do
      forall :b, const(:Bool) do
        eq(const(:Bool), call(const(:bool_or), const(false), var(:b)), var(:b))
      end
    end

    proof do
      lam :b, const(:Bool) do
        refl(var(:b))
      end
    end
  end
end
