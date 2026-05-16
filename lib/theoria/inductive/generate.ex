defmodule Theoria.Inductive.Generate do
  @moduledoc "Generators for declarations derived from inductive specs."

  alias Theoria.Elaborator
  alias Theoria.Env.Reduction
  alias Theoria.Inductive.{Recursor, Spec}
  alias Theoria.Level
  alias Theoria.Syntax, as: S

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
  def nat_eliminators(%Spec{} = spec) do
    base = base_name(spec.name)

    [
      %Recursor{
        name: String.to_atom("#{base}_rec"),
        type: nat_rec_type(spec),
        reduction: %Reduction.NatRec{}
      },
      %Recursor{
        name: String.to_atom("#{base}_ind"),
        type: nat_ind_type(spec),
        reduction: %Reduction.NatInd{}
      }
    ]
  end

  @doc "Generates non-dependent and dependent eliminators for Theoria's List-like shape."
  @spec list_eliminators(Spec.t()) :: [Recursor.t()]
  def list_eliminators(%Spec{} = spec) do
    base = base_name(spec.name)

    [
      %Recursor{
        name: String.to_atom("#{base}_rec"),
        type: list_rec_type(spec),
        reduction: %Reduction.ListRec{}
      },
      %Recursor{
        name: String.to_atom("#{base}_ind"),
        type: list_ind_type(spec),
        reduction: %Reduction.ListInd{}
      }
    ]
  end

  defp bool_rec_type(%Spec{name: name}) do
    u = Level.param(:u)

    S.forall(
      :a,
      S.sort(u),
      S.arrow(
        S.var(:a),
        S.arrow(S.var(:a), S.arrow(S.const(name), S.var(:a)))
      )
    )
    |> Elaborator.elaborate!()
  end

  defp bool_ind_type(%Spec{name: name}, true_name, false_name) do
    u = Level.param(:u)

    S.forall(
      :motive,
      S.arrow(S.const(name), S.sort(u)),
      S.arrow(
        S.app(S.var(:motive), S.const(true_name)),
        S.arrow(
          S.app(S.var(:motive), S.const(false_name)),
          S.forall(:b, S.const(name), S.app(S.var(:motive), S.var(:b)))
        )
      )
    )
    |> Elaborator.elaborate!()
  end

  defp nat_rec_type(%Spec{name: name}) do
    u = Level.param(:u)

    S.forall(
      :a,
      S.sort(u),
      S.arrow(
        S.var(:a),
        S.arrow(
          S.arrow(S.const(name), S.arrow(S.var(:a), S.var(:a))),
          S.arrow(S.const(name), S.var(:a))
        )
      )
    )
    |> Elaborator.elaborate!()
  end

  defp nat_ind_type(%Spec{name: name}) do
    u = Level.param(:u)

    S.forall(
      :motive,
      S.arrow(S.const(name), S.sort(u)),
      S.arrow(
        S.app(S.var(:motive), S.const(:zero)),
        S.arrow(
          S.forall(
            :n,
            S.const(name),
            S.arrow(
              S.app(S.var(:motive), S.var(:n)),
              S.app(S.var(:motive), S.app(S.const(:succ), S.var(:n)))
            )
          ),
          S.forall(:n, S.const(name), S.app(S.var(:motive), S.var(:n)))
        )
      )
    )
    |> Elaborator.elaborate!()
  end

  defp list_rec_type(%Spec{name: name}) do
    u = Level.param(:u)
    v = Level.param(:v)

    S.forall(
      :a,
      S.sort(u),
      S.forall(
        :b,
        S.sort(v),
        S.arrow(
          S.var(:b),
          S.arrow(
            S.arrow(
              S.var(:a),
              S.arrow(list_type(name, u, S.var(:a)), S.arrow(S.var(:b), S.var(:b)))
            ),
            S.arrow(list_type(name, u, S.var(:a)), S.var(:b))
          )
        )
      )
    )
    |> Elaborator.elaborate!()
  end

  defp list_ind_type(%Spec{name: name}) do
    u = Level.param(:u)
    v = Level.param(:v)

    S.forall(
      :a,
      S.sort(u),
      S.forall(
        :motive,
        S.arrow(list_type(name, u, S.var(:a)), S.sort(v)),
        S.arrow(
          S.app(S.var(:motive), S.app(S.const(:list_nil, [u]), S.var(:a))),
          S.arrow(
            S.forall(
              :x,
              S.var(:a),
              S.forall(
                :xs,
                list_type(name, u, S.var(:a)),
                S.arrow(
                  S.app(S.var(:motive), S.var(:xs)),
                  S.app(
                    S.var(:motive),
                    S.const(:list_cons, [u])
                    |> S.app(S.var(:a))
                    |> S.app(S.var(:x))
                    |> S.app(S.var(:xs))
                  )
                )
              )
            ),
            S.forall(:xs, list_type(name, u, S.var(:a)), S.app(S.var(:motive), S.var(:xs)))
          )
        )
      )
    )
    |> Elaborator.elaborate!()
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
