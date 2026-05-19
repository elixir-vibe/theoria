defmodule Theoria.Kernel.GeneratedTerm.Report do
  @moduledoc """
  Structured generated-term differential coverage summary.

  Experimental before 1.0; the shape may change.
  """

  @enforce_keys [:total, :families, :size, :max_terms]
  defstruct [:total, :families, :size, :max_terms]

  @type t :: %__MODULE__{
          total: non_neg_integer(),
          families: %{atom() => non_neg_integer()},
          size: non_neg_integer(),
          max_terms: pos_integer()
        }

  @spec total(t()) :: non_neg_integer()
  def total(%__MODULE__{total: total}), do: total

  @spec families(t()) :: %{atom() => non_neg_integer()}
  def families(%__MODULE__{families: families}), do: families

  @spec family_count(t(), atom()) :: non_neg_integer()
  def family_count(%__MODULE__{families: families}, family), do: Map.get(families, family, 0)

  @spec new([Theoria.Kernel.GeneratedTerm.t()], keyword()) :: t()
  def new(terms, opts) do
    %__MODULE__{
      total: length(terms),
      families: count_families(terms),
      size: Keyword.fetch!(opts, :size),
      max_terms: Keyword.fetch!(opts, :max_terms)
    }
  end

  defp count_families(terms) do
    terms
    |> Enum.map(&family/1)
    |> Enum.frequencies()
  end

  defp family(%Theoria.Kernel.GeneratedTerm{name: {family, _index}}), do: family
  defp family(%Theoria.Kernel.GeneratedTerm{name: family}) when is_atom(family), do: family
  defp family(%Theoria.Kernel.GeneratedTerm{}), do: :unnamed
end
