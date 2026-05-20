alias Theoria.Spec.Examples
alias Theoria.Spec.Report

report = Theoria.Spec.report(Examples.claims())

IO.puts("spec claims")
IO.puts("  total: #{Report.total(report)}")
IO.puts("  valid: #{Report.valid(report)}")
IO.puts("  invalid: #{Report.invalid(report)}")
IO.puts("  kinds: #{inspect(Report.kinds(report))}")

Enum.each(Report.claims(report), fn claim ->
  IO.puts("  #{Theoria.Spec.Claim.kind(claim)} valid=#{Theoria.Spec.Claim.valid?(claim)} reason=#{inspect(Theoria.Spec.Claim.reason(claim))}")
end)
