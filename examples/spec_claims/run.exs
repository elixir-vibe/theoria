alias Theoria.Spec.Effect
alias Theoria.Spec.Finite
alias Theoria.Spec.Graph
alias Theoria.Spec.Report
alias Theoria.Spec.Typespec
alias Theoria.Typespec.Type

reachable = Graph.new([{:controller, :context}, {:context, :repo}])
path = Graph.path_claim(reachable, :controller, :repo, [:controller, :context, :repo])

no_new_effect = Effect.deltas([:write], [:read]) |> hd()
new_effect = Effect.deltas([:pure], [:write]) |> hd()

allowed_deps = Finite.subset_claim([:context], [:context, :schema])

old_type = %Type{kind: :integer}
new_type = %Type{kind: :non_neg_integer}
typespec = Typespec.compatibility(old_type, new_type)

report = Report.new([path, no_new_effect, new_effect, allowed_deps, typespec])

IO.puts("spec claims")
IO.puts("  total: #{Report.total(report)}")
IO.puts("  valid: #{Report.valid(report)}")
IO.puts("  invalid: #{Report.invalid(report)}")
IO.puts("  kinds: #{inspect(Report.kinds(report))}")

Enum.each(Report.claims(report), fn claim ->
  IO.puts("  #{Theoria.Spec.Claim.kind(claim)} valid=#{Theoria.Spec.Claim.valid?(claim)} reason=#{inspect(Theoria.Spec.Claim.reason(claim))}")
end)
