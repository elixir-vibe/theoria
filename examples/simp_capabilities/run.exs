{:ok, env} = Theoria.Prelude.env()

IO.puts("proof capabilities")

Enum.each(Theoria.Rewrite.Proof.Capabilities.matrix(), fn entry ->
  IO.puts("  #{inspect(entry.path)}: #{entry.capability.reason} supported=#{entry.capability.supported?}")
end)

zero = Theoria.Term.const(:zero)
one = Theoria.Term.app(Theoria.Term.const(:succ), zero)
term = Theoria.Term.const(:nat_add) |> Theoria.Term.app(zero) |> Theoria.Term.app(one)

result = Theoria.Simp.normalize(env, term, prove: true, realize: :lazy)

IO.puts("\nsimp result")
IO.puts("  proof checked?: #{Theoria.Simp.Result.proof_checked?(result)}")
IO.puts("  proof strategy: #{inspect(Theoria.Simp.Result.proof_strategy(result))}")
IO.puts("  proof status counts: #{inspect(Theoria.Simp.Result.proof_status_counts(result))}")

Enum.each(result.steps, fn step ->
  IO.puts("  step #{inspect(step.path)}: #{Theoria.Simp.Step.proof_status(step)}")
end)
