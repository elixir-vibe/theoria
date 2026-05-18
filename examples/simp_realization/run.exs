alias Theoria.Prelude
alias Theoria.Simp
alias Theoria.Term

{:ok, env} = Prelude.env()
one = Term.app(Term.const(:succ), Term.const(:zero))
term = Term.const(:nat_add) |> Term.app(Term.const(:zero)) |> Term.app(one)

{:ok, artifact} = Simp.realize(env, term)
IO.puts("realized #{inspect(artifact.identity)}")

{:ok, _env, theorem} = Simp.add_theorem(env, :nat_add_zero_simp_example, term)
IO.puts("installed #{theorem.name}")
