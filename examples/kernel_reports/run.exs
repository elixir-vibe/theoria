{:ok, env} = Theoria.Prelude.env()
report = Theoria.Kernel.Differential.run(env)

IO.puts("kernel differential")
IO.puts("  ok?: #{Theoria.Kernel.Differential.Report.ok?(report)}")
IO.puts("  total checks: #{Theoria.Kernel.Differential.Report.total_checks(report)}")
IO.puts("  replay checks: #{Theoria.Kernel.Differential.Report.total_replay_checks(report)}")
IO.puts("  failures: #{Theoria.Kernel.Differential.Report.failure_count(report)}")
IO.puts("  total ms: #{report.timings.total_ms}")

IO.puts("\ntheorem modules")

Enum.each(report.theorem_modules, fn module_report ->
  IO.puts(
    "  #{inspect(module_report.module)}: checks=#{module_report.checks} replay=#{module_report.replay_checks} ok?=#{Theoria.Kernel.TheoremModuleReport.ok?(module_report)}"
  )
end)
