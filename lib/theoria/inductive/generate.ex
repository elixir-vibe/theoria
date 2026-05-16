defmodule Theoria.Inductive.Generate do
  @moduledoc "Generators for declarations derived from inductive specs."

  alias Theoria.Env.Reduction
  alias Theoria.Inductive.{Recursor, Spec}
  alias Theoria.Level
  alias Theoria.Syntax, as: S

  import Theoria.DSL, only: [elab!: 1, term: 1]

  @doc "Generates non-dependent and dependent eliminators for a Bool-like inductive."
  @spec bool_eliminators(Spec.t()) :: [Recursor.t()]
  def bool_eliminators(%Spec{constructors: [on_true, on_false]} = spec) do
    base = base_name(spec.name)

    [
      %Recursor{
        name: String.to_atom("#{base}_rec"),
        type: bool_rec_type(spec),
        reduction: %Reduction.BoolRec{}
      },
      %Recursor{
        name: String.to_atom("#{base}_ind"),
        type: bool_ind_type(spec, on_true.name, on_false.name),
        reduction: %Reduction.BoolInd{}
      }
    ]
  end

  @doc "Generates non-dependent and dependent eliminators for a Nat-like inductive."
  @spec nat_eliminators(Spec.t()) :: [Recursor.t()]
  def nat_eliminators(%Spec{constructors: [zero, succ]} = spec) do
    base = base_name(spec.name)

    [
      %Recursor{
        name: String.to_atom("#{base}_rec"),
        type: nat_rec_type(spec),
        reduction: %Reduction.NatRec{}
      },
      %Recursor{
        name: String.to_atom("#{base}_ind"),
        type: nat_ind_type(spec, zero.name, succ.name),
        reduction: %Reduction.NatInd{}
      }
    ]
  end

  @doc "Generates non-dependent and dependent eliminators for Theoria's List-like shape."
  @spec list_eliminators(Spec.t()) :: [Recursor.t()]
  def list_eliminators(%Spec{constructors: [nil_constructor, cons]} = spec) do
    base = base_name(spec.name)

    [
      %Recursor{
        name: String.to_atom("#{base}_rec"),
        type: list_rec_type(spec),
        reduction: %Reduction.ListRec{}
      },
      %Recursor{
        name: String.to_atom("#{base}_ind"),
        type: list_ind_type(spec, nil_constructor.name, cons.name),
        reduction: %Reduction.ListInd{}
      }
    ]
  end

  defp bool_rec_type(%Spec{name: name}) do
    u = Level.param(:u)
    bool = S.const(name)

    term do
      forall :a, sort(^u) do
        a ~> (a ~> (^bool ~> a))
      end
    end
    |> elab!()
  end

  defp bool_ind_type(%Spec{name: name}, true_name, false_name) do
    u = Level.param(:u)
    bool = S.const(name)
    on_true = S.const(true_name)
    on_false = S.const(false_name)

    term do
      forall :motive, ^bool ~> sort(^u) do
        app(motive, ^on_true)
        ~> (app(motive, ^on_false)
            ~> forall :b, ^bool do
              app(motive, b)
            end)
      end
    end
    |> elab!()
  end

  defp nat_rec_type(%Spec{name: name}) do
    u = Level.param(:u)
    nat = S.const(name)

    term do
      forall :a, sort(^u) do
        a ~> (^nat ~> (a ~> a) ~> (^nat ~> a))
      end
    end
    |> elab!()
  end

  defp nat_ind_type(%Spec{name: name}, zero_name, succ_name) do
    u = Level.param(:u)
    nat = S.const(name)
    zero = S.const(zero_name)
    succ = S.const(succ_name)

    term do
      forall :motive, ^nat ~> sort(^u) do
        app(motive, ^zero)
        ~> (forall :n, ^nat do
              app(motive, n) ~> app(motive, app(^succ, n))
            end
            ~> forall :n, ^nat do
              app(motive, n)
            end)
      end
    end
    |> elab!()
  end

  defp list_rec_type(%Spec{name: name}) do
    u = Level.param(:u)
    v = Level.param(:v)
    list_a = list_type(name, u, S.var(:a))

    term do
      forall :a, sort(^u) do
        forall :b, sort(^v) do
          b ~> (a ~> (^list_a ~> (b ~> b)) ~> (^list_a ~> b))
        end
      end
    end
    |> elab!()
  end

  defp list_ind_type(%Spec{name: name}, nil_name, cons_name) do
    u = Level.param(:u)
    v = Level.param(:v)
    list_a = list_type(name, u, S.var(:a))
    nil_a = S.app(S.const(nil_name, [u]), S.var(:a))

    cons_a_x_xs =
      S.const(cons_name, [u]) |> S.app(S.var(:a)) |> S.app(S.var(:x)) |> S.app(S.var(:xs))

    term do
      forall :a, sort(^u) do
        forall :motive, ^list_a ~> sort(^v) do
          app(motive, ^nil_a)
          ~> (forall :x, a do
                forall :xs, ^list_a do
                  app(motive, xs) ~> app(motive, ^cons_a_x_xs)
                end
              end
              ~> forall :xs, ^list_a do
                app(motive, xs)
              end)
        end
      end
    end
    |> elab!()
  end

  defp list_type(name, level, element) do
    S.app(S.const(name, [level]), element)
  end

  defp base_name(name) do
    name
    |> Atom.to_string()
    |> String.trim_leading("Elixir.")
    |> Macro.underscore()
    |> String.replace("/", "_")
  end
end
