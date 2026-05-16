defmodule Theoria.Library.Logic.Theorems do
  @moduledoc """
  Theorem corpus for `Theoria.Library.Logic`.

  These proofs cover the initial logical declarations for implication-like
  function types, false elimination, negation, and conjunction. They exercise
  the public theorem DSL against both `Theoria.Library.Logic.env/0` and the
  standard `Theoria.Prelude.env/0`.
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
            term do
              and_intro(q, p, and_right(p, q, h), and_left(p, q, h))
            end
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

  theorem :not_false do
    type do
      call(const(:not), const(:False))
    end

    proof do
      lam :hfalse, const(:False) do
        var(:hfalse)
      end
    end
  end

  theorem :contradiction do
    type do
      forall :p, prop() do
        forall :hp, var(:p) do
          forall :hnp, call(const(:not), var(:p)) do
            const(:False)
          end
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

  theorem :and_assoc_left do
    type do
      forall :p, prop() do
        forall :q, prop() do
          forall :r, prop() do
            forall :h, call(const(:and), call(const(:and), var(:p), var(:q)), var(:r)) do
              call(const(:and), var(:p), call(const(:and), var(:q), var(:r)))
            end
          end
        end
      end
    end

    proof do
      lam :p, prop() do
        lam :q, prop() do
          lam :r, prop() do
            lam :h, call(const(:and), call(const(:and), var(:p), var(:q)), var(:r)) do
              call(
                const(:and_intro),
                var(:p),
                call(const(:and), var(:q), var(:r)),
                call(
                  const(:and_left),
                  var(:p),
                  var(:q),
                  call(
                    const(:and_left),
                    call(const(:and), var(:p), var(:q)),
                    var(:r),
                    var(:h)
                  )
                ),
                call(
                  const(:and_intro),
                  var(:q),
                  var(:r),
                  call(
                    const(:and_right),
                    var(:p),
                    var(:q),
                    call(
                      const(:and_left),
                      call(const(:and), var(:p), var(:q)),
                      var(:r),
                      var(:h)
                    )
                  ),
                  call(const(:and_right), call(const(:and), var(:p), var(:q)), var(:r), var(:h))
                )
              )
            end
          end
        end
      end
    end
  end

  theorem :and_assoc_right do
    type do
      forall :p, prop() do
        forall :q, prop() do
          forall :r, prop() do
            forall :h, call(const(:and), var(:p), call(const(:and), var(:q), var(:r))) do
              call(const(:and), call(const(:and), var(:p), var(:q)), var(:r))
            end
          end
        end
      end
    end

    proof do
      lam :p, prop() do
        lam :q, prop() do
          lam :r, prop() do
            lam :h, call(const(:and), var(:p), call(const(:and), var(:q), var(:r))) do
              call(
                const(:and_intro),
                call(const(:and), var(:p), var(:q)),
                var(:r),
                call(
                  const(:and_intro),
                  var(:p),
                  var(:q),
                  call(const(:and_left), var(:p), call(const(:and), var(:q), var(:r)), var(:h)),
                  call(
                    const(:and_left),
                    var(:q),
                    var(:r),
                    call(const(:and_right), var(:p), call(const(:and), var(:q), var(:r)), var(:h))
                  )
                ),
                call(
                  const(:and_right),
                  var(:q),
                  var(:r),
                  call(const(:and_right), var(:p), call(const(:and), var(:q), var(:r)), var(:h))
                )
              )
            end
          end
        end
      end
    end
  end
end
