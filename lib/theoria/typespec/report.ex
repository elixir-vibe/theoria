defmodule Theoria.Typespec.Report do
  @moduledoc "Structured report for normalized Elixir typespec contracts."

  alias Theoria.Typespec.Contract

  @type t :: %__MODULE__{
          module: module(),
          contracts: [Contract.t()],
          total: non_neg_integer(),
          unsupported: non_neg_integer()
        }

  @enforce_keys [:module, :contracts, :total, :unsupported]
  defstruct @enforce_keys

  @doc "Builds a report for a module's normalized contracts."
  @spec new(module(), [Contract.t()]) :: t()
  def new(module, contracts) when is_atom(module) and is_list(contracts) do
    %__MODULE__{
      module: module,
      contracts: contracts,
      total: length(contracts),
      unsupported: Enum.count(contracts, &Contract.unsupported?/1)
    }
  end

  @doc "Returns normalized contracts."
  @spec contracts(t()) :: [Contract.t()]
  def contracts(%__MODULE__{contracts: contracts}), do: contracts

  @doc "Returns total contract count."
  @spec total(t()) :: non_neg_integer()
  def total(%__MODULE__{total: total}), do: total

  @doc "Returns contracts containing unsupported type fragments."
  @spec unsupported(t()) :: non_neg_integer()
  def unsupported(%__MODULE__{unsupported: unsupported}), do: unsupported
end
