defmodule DownstreamProofs do
  @moduledoc "Small downstream theorem module used by Theoria smoke tests."

  use Theoria.DSL

  theorem :identity do
    type do
      forall :a, type(0) do
        forall :x, var(:a) do
          var(:a)
        end
      end
    end

    proof do
      lam :a, type(0) do
        lam :x, var(:a) do
          var(:x)
        end
      end
    end
  end

  theorem :identity_again do
    type do
      forall :a, type(0) do
        forall :x, var(:a) do
          var(:a)
        end
      end
    end

    proof do
      const(:identity)
    end
  end
end
