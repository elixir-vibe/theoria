defmodule Theoria.Certificate.Report do
  @moduledoc """
  Structured summary of obligation certificates.

  Certificate reports are the JSON-friendly shape for tool integrations. They
  summarize checked, failed, and unchecked claims without requiring consumers to
  inspect every certificate manually.
  """

  alias Theoria.Certificate

  @type t :: %__MODULE__{
          certificates: [Certificate.t()],
          total: non_neg_integer(),
          checked: non_neg_integer(),
          failed: non_neg_integer(),
          unchecked: non_neg_integer()
        }

  @enforce_keys [:certificates, :total, :checked, :failed, :unchecked]
  defstruct @enforce_keys

  @doc "Builds a report from certificates."
  @spec new([Certificate.t()]) :: t()
  def new(certificates) when is_list(certificates) do
    counts = certificates |> Enum.map(&Certificate.status/1) |> Enum.frequencies()

    %__MODULE__{
      certificates: certificates,
      total: length(certificates),
      checked: Map.get(counts, :checked, 0),
      failed: Map.get(counts, :failed, 0),
      unchecked: Map.get(counts, :unchecked, 0)
    }
  end

  @doc "Returns certificates in report order."
  @spec certificates(t()) :: [Certificate.t()]
  def certificates(%__MODULE__{certificates: certificates}), do: certificates

  @doc "Returns the total certificate count."
  @spec total(t()) :: non_neg_integer()
  def total(%__MODULE__{total: total}), do: total

  @doc "Returns checked certificate count."
  @spec checked(t()) :: non_neg_integer()
  def checked(%__MODULE__{checked: checked}), do: checked

  @doc "Returns failed certificate count."
  @spec failed(t()) :: non_neg_integer()
  def failed(%__MODULE__{failed: failed}), do: failed

  @doc "Returns unchecked certificate count."
  @spec unchecked(t()) :: non_neg_integer()
  def unchecked(%__MODULE__{unchecked: unchecked}), do: unchecked
end
