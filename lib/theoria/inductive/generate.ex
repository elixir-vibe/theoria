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

  defp base_name(name) do
    name
    |> Atom.to_string()
    |> String.trim_leading("Elixir.")
    |> Macro.underscore()
    |> String.replace("/", "_")
  end
end
