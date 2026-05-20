defmodule Theoria.Theorem.Report do
  @moduledoc """
  Structured report for a theorem-module checking run.

  The report is produced by `mix theoria.theorems --json` and contains one
  `Theoria.Theorem.ModuleReport` per checked module plus the total theorem count.

      iex> module_report = %Theoria.Theorem.ModuleReport{
      ...>   module: MyProofs,
      ...>   theorem_names: [:identity],
      ...>   theorem_count: 1,
      ...>   installed?: false
      ...> }
      iex> report = Theoria.Theorem.Report.new([module_report])
      iex> Theoria.Theorem.Report.total(report)
      1
  """

  alias Theoria.Theorem.ModuleReport

  @type t :: %__MODULE__{modules: [ModuleReport.t()], total: non_neg_integer()}

  @enforce_keys [:modules, :total]
  defstruct @enforce_keys

  @doc "Builds a theorem checking report from module reports."
  @spec new([ModuleReport.t()]) :: t()
  def new(modules) when is_list(modules) do
    %__MODULE__{modules: modules, total: Enum.reduce(modules, 0, &(&1.theorem_count + &2))}
  end

  @doc "Returns module reports in checking order."
  @spec modules(t()) :: [ModuleReport.t()]
  def modules(%__MODULE__{modules: modules}), do: modules

  @doc "Returns the total checked theorem count."
  @spec total(t()) :: non_neg_integer()
  def total(%__MODULE__{total: total}), do: total
end
