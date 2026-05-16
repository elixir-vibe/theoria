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

  theorem :const do
    type do
      forall :p, prop() do
        forall :q, prop() do
          forall :hp, var(:p) do
            forall :_hq, var(:q) do
              var(:p)
            end
          end
        end
      end
    end

    proof do
      lam :p, prop() do
        lam :q, prop() do
          lam :hp, var(:p) do
            lam :_hq, var(:q) do
              var(:hp)
            end
          end
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

  theorem :double_negation_intro do
    type do
      forall :p, prop() do
        forall :hp, var(:p) do
          call(const(:not), call(const(:not), var(:p)))
        end
      end
    end

    proof do
      lam :p, prop() do
        lam :hp, var(:p) do
          lam :hnp, call(const(:not), var(:p)) do
            call(var(:hnp), var(:hp))
          end
        end
      end
    end
  end

  theorem :and_left_eta do
    type do
      forall :p, prop() do
        forall :q, prop() do
          forall :h, call(const(:and), var(:p), var(:q)) do
            var(:p)
          end
        end
      end
    end

    proof do
      lam :p, prop() do
        lam :q, prop() do
          lam :h, call(const(:and), var(:p), var(:q)) do
            call(const(:and_left), var(:p), var(:q), var(:h))
          end
        end
      end
    end
  end

  theorem :and_right_eta do
    type do
      forall :p, prop() do
        forall :q, prop() do
          forall :h, call(const(:and), var(:p), var(:q)) do
            var(:q)
          end
        end
      end
    end

    proof do
      lam :p, prop() do
        lam :q, prop() do
          lam :h, call(const(:and), var(:p), var(:q)) do
            call(const(:and_right), var(:p), var(:q), var(:h))
          end
        end
      end
    end
  end

  theorem :and_comm do
    type do
      forall :p, prop() do
        forall :q, prop() do
          forall :h, call(const(:and), var(:p), var(:q)) do
            call(const(:and), var(:q), var(:p))
          end
        end
      end
    end

    proof do
      lam :p, prop() do
        lam :q, prop() do
          lam :h, call(const(:and), var(:p), var(:q)) do
            call(
              const(:and_intro),
              var(:q),
              var(:p),
              call(const(:and_right), var(:p), var(:q), var(:h)),
              call(const(:and_left), var(:p), var(:q), var(:h))
            )
          end
        end
      end
    end
  end

  theorem :and_intro_eta do
    type do
      forall :p, prop() do
        forall :q, prop() do
          forall :hp, var(:p) do
            forall :hq, var(:q) do
              call(const(:and), var(:p), var(:q))
            end
          end
        end
      end
    end

    proof do
      lam :p, prop() do
        lam :q, prop() do
          lam :hp, var(:p) do
            lam :hq, var(:q) do
              call(const(:and_intro), var(:p), var(:q), var(:hp), var(:hq))
            end
          end
        end
      end
    end
  end
end
