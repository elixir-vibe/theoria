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
        failures: Enum.map(report.failures, &encode_failure/1)
      },
      opts
    )
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
