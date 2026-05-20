defmodule Theoria.Spec.Examples do
  @moduledoc """
  Built-in structural claim examples used by docs and `mix theoria.spec`.

  These examples model the kind of finite facts Reach, ex_ast, and Vibe can emit:
  graph path witnesses, no-new-effect claims, finite subset checks, and shallow
  typespec compatibility.
  """

  alias Theoria.Spec.Effect
  alias Theoria.Spec.Finite
  alias Theoria.Spec.Graph
  alias Theoria.Spec.Typespec
  alias Theoria.Typespec.Type

  @doc "Returns a small mixed set of valid and invalid structural spec claims."
  @spec claims() :: [term()]
  def claims do
    reachable = Graph.new([{:controller, :context}, {:context, :repo}])
    path = Graph.path_claim(reachable, :controller, :repo, [:controller, :context, :repo])

    no_new_effect = Effect.deltas([:write], [:read]) |> hd()
    new_effect = Effect.deltas([:pure], [:write]) |> hd()

    allowed_deps = Finite.subset_claim([:context], [:context, :schema])

    old_type = %Type{kind: :integer}
    new_type = %Type{kind: :non_neg_integer}
    typespec = Typespec.compatibility(old_type, new_type)

    [path, no_new_effect, new_effect, allowed_deps, typespec]
  end
end
