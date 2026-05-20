defmodule Theoria.Simp.Report do
  @moduledoc "Structured report for a built-in simplification example run."

  alias Theoria.Simp.ExampleReport

  @type t :: %__MODULE__{examples: [ExampleReport.t()]}

  @enforce_keys [:examples]
  defstruct @enforce_keys

  @doc "Builds a simplification report from example reports."
  @spec new([ExampleReport.t()]) :: t()
  def new(examples) when is_list(examples), do: %__MODULE__{examples: examples}

  @doc "Returns example reports in execution order."
  @spec examples(t()) :: [ExampleReport.t()]
  def examples(%__MODULE__{examples: examples}), do: examples
end
