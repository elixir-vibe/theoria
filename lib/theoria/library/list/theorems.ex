defmodule Theoria.Library.List.Theorems do
  @moduledoc "Small proof corpus for the initial List library."

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
end
