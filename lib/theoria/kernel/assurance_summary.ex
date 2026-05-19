defmodule Theoria.Kernel.AssuranceSummary do
  @moduledoc "User-facing summary of kernel assurance coverage."

  alias Theoria.Kernel.Differential

  defmodule Curated do
    @moduledoc "Curated kernel corpus counts."
    @enforce_keys [:infer, :check, :normalize, :defeq, :rejection]
    defstruct [:infer, :check, :normalize, :defeq, :rejection]

    @type t :: %__MODULE__{
            infer: non_neg_integer(),
            check: non_neg_integer(),
            normalize: non_neg_integer(),
            defeq: non_neg_integer(),
            rejection: non_neg_integer()
          }
  end

  defmodule GeneratedTerms do
    @moduledoc "Generated term assurance counts."
    @enforce_keys [:total, :families]
    defstruct [:total, :families]

    @type t :: %__MODULE__{total: non_neg_integer(), families: non_neg_integer()}
  end

  defmodule Environments do
    @moduledoc "Generated environment assurance counts."
    @enforce_keys [:cases, :replay, :normalize, :invalid]
    defstruct [:cases, :replay, :normalize, :invalid]

    @type t :: %__MODULE__{
            cases: non_neg_integer(),
            replay: non_neg_integer(),
            normalize: non_neg_integer(),
            invalid: non_neg_integer()
          }
  end

  defmodule Artifacts do
    @moduledoc "Generated artifact assurance counts."
    @enforce_keys [:generated, :indexed, :replay]
    defstruct [:generated, :indexed, :replay]

    @type t :: %__MODULE__{
            generated: non_neg_integer(),
            indexed: non_neg_integer(),
            replay: non_neg_integer()
          }
  end

  @enforce_keys [:curated, :generated_terms, :environments, :artifacts, :theorems, :replay]
  defstruct [:curated, :generated_terms, :environments, :artifacts, :theorems, :replay]

  @type t :: %__MODULE__{
          curated: Curated.t(),
          generated_terms: GeneratedTerms.t(),
          environments: Environments.t(),
          artifacts: Artifacts.t(),
          theorems: non_neg_integer(),
          replay: non_neg_integer()
        }

  @spec from_report(Differential.Report.t()) :: t()
  def from_report(%Differential.Report{} = report) do
    %__MODULE__{
      curated: %Curated{
        infer: report.infer_count,
        check: report.check_count,
        normalize: report.normalize_count,
        defeq: report.defeq_count,
        rejection: report.rejection_count
      },
      generated_terms: %GeneratedTerms{
        total: report.generated_term_count,
        families: map_size(report.generated_term_families)
      },
      environments: %Environments{
        cases: report.environment_count,
        replay: report.environment_replay_count,
        normalize: report.environment_normalize_count,
        invalid: report.invalid_environment_count
      },
      artifacts: %Artifacts{
        generated: report.generated_artifact_count,
        indexed: report.indexed_artifact_count,
        replay: report.artifact_replay_count
      },
      theorems: report.theorem_count,
      replay: Differential.Report.total_replay_checks(report)
    }
  end
end
