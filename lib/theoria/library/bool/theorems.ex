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
end
