defimpl Jason.Encoder, for: Theoria.Kernel.GeneratedTerm.Report do
  def encode(report, opts) do
    Jason.Encode.map(
      %{
        total: report.total,
        families: report.families,
        size: report.size,
        max_terms: report.max_terms
      },
      opts
    )
  end
end

defimpl Jason.Encoder, for: Theoria.Kernel.GeneratedTerm.Failure do
  def encode(failure, opts) do
    Jason.Encode.map(
      %{
        phase: failure.phase,
        name: inspect(failure.name),
        term: failure.term,
        type: failure.type,
        production: failure.production,
        reference: failure.reference
      },
      opts
    )
  end
end

defimpl Jason.Encoder, for: Theoria.Kernel.EnvironmentCorpus.Report.Case do
  def encode(corpus_case, opts) do
    Jason.Encode.map(
      %{
        name: corpus_case.name,
        replay_checks: corpus_case.replay_checks,
        normalize_checks: corpus_case.normalize_checks,
        failures: Enum.map(corpus_case.failures, &inspect/1)
      },
      opts
    )
  end
end

defimpl Jason.Encoder, for: Theoria.Kernel.EnvironmentCorpus.Report do
  def encode(report, opts) do
    Jason.Encode.map(
      %{
        total: report.total,
        replay_checks: report.replay_checks,
        normalize_checks: report.normalize_checks,
        cases: report.cases,
        failures: Enum.map(report.failures, &inspect/1)
      },
      opts
    )
  end
end

defimpl Jason.Encoder, for: Theoria.Kernel.ProofStrategyReport do
  def encode(report, opts) do
    Jason.Encode.map(%{total: report.total, counts: report.counts}, opts)
  end
end

defimpl Jason.Encoder, for: Theoria.Kernel.Differential.Timings do
  def encode(timings, opts) do
    Jason.Encode.map(
      %{
        infer_ms: timings.infer_ms,
        check_ms: timings.check_ms,
        normalize_ms: timings.normalize_ms,
        defeq_ms: timings.defeq_ms,
        rejection_ms: timings.rejection_ms,
        generated_term_ms: timings.generated_term_ms,
        theorem_ms: timings.theorem_ms,
        generated_artifact_ms: timings.generated_artifact_ms,
        indexed_artifact_ms: timings.indexed_artifact_ms,
        replay_ms: timings.replay_ms,
        artifact_replay_ms: timings.artifact_replay_ms,
        total_ms: timings.total_ms
      },
      opts
    )
  end
end

defimpl Jason.Encoder, for: Theoria.Kernel.Explanation do
  def encode(explanation, opts) do
    Jason.Encode.map(
      %{
        name: explanation.name,
        description: explanation.description,
        trusted: explanation.trusted?,
        boundary: explanation.boundary
      },
      opts
    )
  end
end

defimpl Jason.Encoder, for: Theoria.Kernel.TheoremModuleReport do
  def encode(report, opts) do
    Jason.Encode.map(
      %{
        module: inspect(report.module),
        checks: report.checks,
        replay_checks: report.replay_checks,
        replay_skipped: report.replay_skipped,
        failures: Enum.map(report.failures, &inspect/1)
      },
      opts
    )
  end
end

defimpl Jason.Encoder, for: Theoria.Kernel.Reference.Replay.Failure do
  def encode(failure, opts) do
    Jason.Encode.map(
      %{
        name: inspect(failure.name),
        phase: failure.phase,
        declaration_kind: failure.declaration_kind,
        reason: inspect(failure.reason),
        direct_dependencies: failure.direct_dependencies,
        transitive_dependencies: failure.transitive_dependencies,
        missing_dependencies: failure.missing_dependencies,
        details: inspect(failure.details)
      },
      opts
    )
  end
end

defimpl Jason.Encoder, for: Theoria.Kernel.ArtifactReplay do
  def encode(replay, opts) do
    Jason.Encode.map(
      %{
        checked: Theoria.Kernel.ArtifactReplay.checked(replay),
        generated_checked: replay.generated_checked,
        indexed_checked: replay.indexed_checked,
        skipped: replay.skipped,
        failures: replay.failures
      },
      opts
    )
  end
end

defimpl Jason.Encoder, for: Theoria.Kernel.ArtifactReplay.Skip do
  def encode(skip, opts) do
    Jason.Encode.map(
      %{
        name: inspect(skip.name),
        reason: skip.reason,
        details: inspect(skip.details)
      },
      opts
    )
  end
end

defimpl Jason.Encoder, for: Theoria.Kernel.Differential.Report do
  def encode(report, opts) do
    Jason.Encode.map(
      %{
        infer_checks: report.infer_count,
        check_checks: report.check_count,
        normalize_checks: report.normalize_count,
        defeq_checks: report.defeq_count,
        rejection_checks: report.rejection_count,
        generated_term_checks: report.generated_term_count,
        generated_terms: report.generated_terms,
        environment_cases: report.environment_count,
        environment_replay_checks: report.environment_replay_count,
        environment_normalize_checks: report.environment_normalize_count,
        environment_report: report.environment_report,
        invalid_environment_checks: report.invalid_environment_count,
        theorem_checks: report.theorem_count,
        theorem_modules: report.theorem_modules,
        theorem_replay_checks: report.theorem_replay_count,
        theorem_replay_skipped: report.theorem_replay_skipped,
        generated_artifact_checks: report.generated_artifact_count,
        indexed_artifact_checks: report.indexed_artifact_count,
        proof_strategy_counts: report.proof_strategy_counts,
        proof_strategies: report.proof_strategies,
        replay_checks: report.replay_count,
        replay_skipped: report.replay_skipped,
        artifact_replay_checks: report.artifact_replay_count,
        artifact_replay_skipped: report.artifact_replay_skipped,
        generated_artifact_replay_checks: report.generated_artifact_replay_count,
        indexed_artifact_replay_checks: report.indexed_artifact_replay_count,
        artifact_replay_skips: report.artifact_replay_skips,
        artifact_replay: report.artifact_replay,
        timings: report.timings,
        total_checks: Theoria.Kernel.Differential.Report.total_checks(report),
        total_replay_checks: Theoria.Kernel.Differential.Report.total_replay_checks(report),
        failures: Enum.map(report.failures, &encode_failure/1)
      },
      opts
    )
  end

  defp encode_failure(%Theoria.Kernel.Reference.Replay.Failure{} = failure), do: failure

  defp encode_failure({:generated_term, name, reason}) do
    %{
      kind: :generated_term,
      name: inspect(name),
      reason: reason
    }
  end

  defp encode_failure({name, kind, reason}) do
    %{
      kind: kind,
      name: inspect(name),
      reason: inspect(reason)
    }
  end

  defp encode_failure({kind, name, production, reference}) do
    %{
      kind: kind,
      name: inspect(name),
      production: inspect(production),
      reference: inspect(reference)
    }
  end
end
