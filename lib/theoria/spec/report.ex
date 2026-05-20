defmodule Theoria.Spec.Report do
  @moduledoc """
  Structured summary for `Theoria.Spec.Claim` values.

  Spec reports are useful before a claim becomes a kernel-checked obligation:
  they summarize structural witnesses such as graph paths, finite subset claims,
  effect deltas, and typespec compatibility checks.
  """

  alias Theoria.Spec.Claim

  @type t :: %__MODULE__{
          claims: [term()],
          total: non_neg_integer(),
          valid: non_neg_integer(),
          invalid: non_neg_integer(),
          kinds: %{atom() => non_neg_integer()}
        }

  @enforce_keys [:claims, :total, :valid, :invalid, :kinds]
  defstruct @enforce_keys

  @doc "Builds a report from claim structs implementing `Theoria.Spec.Claim`."
  @spec new([term()]) :: t()
  def new(claims) when is_list(claims) do
    total = length(claims)
    valid = Enum.count(claims, &Claim.valid?/1)

    %__MODULE__{
      claims: claims,
      total: total,
      valid: valid,
      invalid: total - valid,
      kinds: claims |> Enum.map(&Claim.kind/1) |> Enum.frequencies()
    }
  end

  @doc "Returns claims in report order."
  @spec claims(t()) :: [term()]
  def claims(%__MODULE__{claims: claims}), do: claims

  @doc "Returns the total claim count."
  @spec total(t()) :: non_neg_integer()
  def total(%__MODULE__{total: total}), do: total

  @doc "Returns the valid claim count."
  @spec valid(t()) :: non_neg_integer()
  def valid(%__MODULE__{valid: valid}), do: valid

  @doc "Returns the invalid claim count."
  @spec invalid(t()) :: non_neg_integer()
  def invalid(%__MODULE__{invalid: invalid}), do: invalid

  @doc "Returns claim counts by kind."
  @spec kinds(t()) :: %{atom() => non_neg_integer()}
  def kinds(%__MODULE__{kinds: kinds}), do: kinds
end
