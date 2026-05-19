defmodule Theoria.Rewrite.Proof.Capabilities do
  @moduledoc """
  Experimental proof-lifting capability matrix for Theoria 0.6.

  The shape may change before 1.0.
  """

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

      eq_rec_path?(path, :base) ->
        supported(:eq_rec_base_congruence, "EqRec base congruence")

      eq_rec_path?(path, :proof) ->
        supported(:eq_rec_proof_congruence, "EqRec proof congruence")

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
      [:proof, :fun],
      [:base],
      [:base, :arg],
      [:type],
      [:motive]
    ]

  defp application_path?(path), do: Enum.all?(path, &(&1 in [:fun, :arg]))

  defp eq_rec_path?([field], field) when field in [:base, :proof], do: true

  defp eq_rec_path?([field | rest], field) when field in [:base, :proof],
    do: explain(rest).supported?

  defp eq_rec_path?(_path, _field), do: false

  defp supported(reason, description),
    do: %Capability{supported?: true, reason: reason, description: description}

  defp unsupported(reason, description),
    do: %Capability{supported?: false, reason: reason, description: description}
end
