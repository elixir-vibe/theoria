defmodule Theoria.Validation.Report do
  @moduledoc "Summary of a Theoria validation run."

  @enforce_keys [
    :categories,
    :theorem_count,
    :defeq_count,
    :inductive_count,
    :equation_count,
    :axioms
  ]
  defstruct [
    :categories,
    :theorem_count,
    :defeq_count,
    :inductive_count,
    :equation_count,
    :axioms
  ]

  @type t :: %__MODULE__{
          categories: [atom()],
          theorem_count: non_neg_integer(),
          defeq_count: non_neg_integer(),
          inductive_count: non_neg_integer(),
          equation_count: non_neg_integer(),
          axioms: MapSet.t(atom())
        }
end
