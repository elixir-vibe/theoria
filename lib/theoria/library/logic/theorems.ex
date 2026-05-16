defmodule Theoria.Library.Logic.Theorems do
  @moduledoc """
  Small proof corpus for the initial logic library.

  These theorems exercise the public theorem DSL against `Theoria.Library.Logic.env/0`.
  """

  use Theoria.DSL

  theorem :identity do
    type do
      forall :p, prop() do
        arrow(var(:p), var(:p))
      end
    end

    proof do
      lam :p, prop() do
        lam :hp, var(:p) do
          var(:hp)
        end
      end
    end
  end

  theorem :false_elim_eta do
    type do
      forall :p, prop() do
        arrow(const(:False), var(:p))
      end
    end

    proof do
      lam :p, prop() do
        lam :hfalse, const(:False) do
          call(const(:false_elim), var(:p), var(:hfalse))
        end
      end
    end
  end
end
