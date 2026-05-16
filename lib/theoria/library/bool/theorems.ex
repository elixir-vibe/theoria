defmodule Theoria.Library.Bool.Theorems do
  @moduledoc "Small proof corpus for the initial Bool library."

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
end
