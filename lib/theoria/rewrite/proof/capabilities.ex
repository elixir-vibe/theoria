defmodule Theoria.Rewrite.Proof.Capabilities do
  @moduledoc "Explains proof-producing rewrite support for structural paths."

  alias Theoria.Rewrite.Proof.Capability
  alias Theoria.Rewrite.Proof.Capability.Entry

  @type capability :: Capability.t()

  @spec explain([atom()]) :: capability()
  def explain([]), do: supported(:top_level, "top-level rule proof")

  def explain(path) when is_list(path) do
    cond do
      application_path?(path) ->
        supported(:application_congruence, "application congruence")

      path in [[:left], [:right]] ->
        supported(:equality_side, "equality-side transport")

      path in [[:domain], [:body]] ->
        unsupported(:binder_boundary, "binder paths remain kernel-checked boundaries")

      path in [[:proof], [:base]] ->
        unsupported(:eq_rec_boundary, "EqRec paths remain kernel-checked boundaries")

      true ->
        unsupported(:unknown_path, "no proof lifting rule for this path")
    end
  end

  @spec supported?([atom()]) :: boolean()
  def supported?(path), do: explain(path).supported?

  @spec matrix() :: [Entry.t()]
  def matrix do
    Enum.map(matrix_paths(), fn path -> %Entry{path: path, capability: explain(path)} end)
  end

  @spec matrix_paths() :: [[atom()]]
  def matrix_paths,
    do: [
      [],
      [:arg],
      [:arg, :arg],
      [:fun],
      [:left],
      [:right],
      [:body],
      [:domain],
      [:proof],
      [:base]
    ]

  defp application_path?(path), do: Enum.all?(path, &(&1 in [:fun, :arg]))

  defp supported(reason, description),
    do: %Capability{supported?: true, reason: reason, description: description}

  defp unsupported(reason, description),
    do: %Capability{supported?: false, reason: reason, description: description}
end
