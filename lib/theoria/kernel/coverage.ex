defmodule Theoria.Kernel.Coverage do
  @moduledoc "Kernel assurance coverage summary."

  alias Theoria.Env
  alias Theoria.Kernel.Differential.Report
  alias Theoria.Kernel.Reference
  alias Theoria.Term

  @supported_terms [
    Term.Sort,
    Term.Const,
    Term.App,
    Term.Lam,
    Term.Forall,
    Term.BVar,
    Term.Let,
    Term.Eq,
    Term.Refl,
    Term.EqRec
  ]

  @property_families [
    "Bool terms",
    "Nat terms",
    "List Bool terms",
    "Vec Bool terms",
    "List eliminator applications",
    "closed equality proofs",
    "deterministic generated typed terms",
    "generated let terms",
    "generated forall terms"
  ]

  @spec summary(Env.t(), Report.t()) :: map()
  def summary(%Env{} = env, %Report{} = report) do
    declarations = Env.declarations(env)

    %{
      supported_term_constructors: Enum.map(@supported_terms, &inspect/1),
      unsupported_term_constructors: Enum.map(Reference.unsupported_terms(), &inspect/1),
      declaration_kinds: declaration_kinds(env, declarations),
      theorem_module_checks: report.theorem_count,
      generated_term_checks: report.generated_term_count,
      generated_term_families: report.generated_term_families,
      generated_artifact_checks: report.generated_artifact_count,
      indexed_artifact_checks: report.indexed_artifact_count,
      proof_strategy_counts: report.proof_strategy_counts,
      replay_checks: report.replay_count,
      replay_skipped: report.replay_skipped,
      artifact_replay_checks: report.artifact_replay_count,
      artifact_replay_skipped: report.artifact_replay_skipped,
      generated_artifact_replay_checks: report.generated_artifact_replay_count,
      indexed_artifact_replay_checks: report.indexed_artifact_replay_count,
      artifact_replay_skips: report.artifact_replay_skips,
      property_families: @property_families
    }
  end

  defp declaration_kinds(env, declarations) do
    Enum.flat_map(declarations, fn name ->
      case Env.fetch(env, name) do
        {:ok, constant} -> [constant.kind]
        :error -> []
      end
    end)
    |> Enum.frequencies()
  end
end
