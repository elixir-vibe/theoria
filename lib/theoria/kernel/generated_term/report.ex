defmodule Theoria.Kernel.GeneratedTerm.Report do
  @moduledoc "Structured generated-term differential coverage summary."

  @enforce_keys [:total, :families, :size, :max_terms]
  defstruct [:total, :families, :size, :max_terms]

  @type t :: %__MODULE__{
          total: non_neg_integer(),
          families: %{atom() => non_neg_integer()},
          size: non_neg_integer(),
          max_terms: pos_integer()
        }

  @spec new([Theoria.Kernel.GeneratedTerm.t()], keyword()) :: t()
  def new(terms, opts) do
    %__MODULE__{
      total: length(terms),
      families: families(terms),
      size: Keyword.fetch!(opts, :size),
      max_terms: Keyword.fetch!(opts, :max_terms)
    }
  end

  defp families(terms) do
    terms
    |> Enum.map(&family/1)
    |> Enum.frequencies()
  end

  defp family(%Theoria.Kernel.GeneratedTerm{name: {family, _index}}), do: family
  defp family(%Theoria.Kernel.GeneratedTerm{name: family}) when is_atom(family), do: family
  defp family(%Theoria.Kernel.GeneratedTerm{}), do: :unnamed
end
