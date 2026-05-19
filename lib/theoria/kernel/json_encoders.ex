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
        theorem_checks: report.theorem_count,
        generated_artifact_checks: report.generated_artifact_count,
        indexed_artifact_checks: report.indexed_artifact_count,
        replay_checks: report.replay_count,
        replay_skipped: report.replay_skipped,
        artifact_replay_checks: report.artifact_replay_count,
        artifact_replay_skipped: report.artifact_replay_skipped,
        generated_artifact_replay_checks: report.generated_artifact_replay_count,
        indexed_artifact_replay_checks: report.indexed_artifact_replay_count,
        artifact_replay_skips: report.artifact_replay_skips,
        failures: Enum.map(report.failures, &encode_failure/1)
      },
      opts
    )
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
      name: name,
      production: inspect(production),
      reference: inspect(reference)
    }
  end
end
