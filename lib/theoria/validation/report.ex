defmodule Theoria.Validation.Report do
  @moduledoc "Summary of a Theoria validation run."

  @enforce_keys [
    :categories,
    :theorem_count,
    :defeq_count,
    :inductive_count,
    :equations,
    :generated_equation_count,
    :matcher_metadata_count,
    :indexed_matcher_count,
    :indexed_matcher_equation_count,
    :indexed_matcher_statement_count,
    :indexed_matcher_lemma_count,
    :indexed_matcher_realization_count,
    :matcher_equation_count,
    :axioms
  ]
  defstruct [
    :categories,
    :theorem_count,
    :defeq_count,
    :inductive_count,
    :equations,
    :generated_equation_count,
    :matcher_metadata_count,
    :indexed_matcher_count,
    :indexed_matcher_equation_count,
    :indexed_matcher_statement_count,
    :indexed_matcher_lemma_count,
    :indexed_matcher_realization_count,
    :matcher_equation_count,
    :axioms
  ]

  @type t :: %__MODULE__{
          categories: [atom()],
          theorem_count: non_neg_integer(),
          defeq_count: non_neg_integer(),
          inductive_count: non_neg_integer(),
          equations: [Theoria.Equation.Info.t()],
          generated_equation_count: non_neg_integer(),
          matcher_metadata_count: non_neg_integer(),
          indexed_matcher_count: non_neg_integer(),
          indexed_matcher_equation_count: non_neg_integer(),
          indexed_matcher_statement_count: non_neg_integer(),
          indexed_matcher_lemma_count: non_neg_integer(),
          indexed_matcher_realization_count: non_neg_integer(),
          matcher_equation_count: non_neg_integer(),
          axioms: MapSet.t(atom())
        }

  @doc "Returns the number of stored equation metadata entries."
  @spec equation_count(t()) :: non_neg_integer()
  def equation_count(%__MODULE__{equations: equations}), do: length(equations)
end
