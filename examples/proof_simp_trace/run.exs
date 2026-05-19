{:ok, env} = Theoria.Prelude.env()

zero = Theoria.Term.const(:zero)
one = Theoria.Term.app(Theoria.Term.const(:succ), zero)
nat = Theoria.Term.const(:Nat)
zero_eq_one = Theoria.Term.eq(nat, zero, one)
{:ok, env} = Theoria.Kernel.add_axiom(env, :zero_eq_one, zero_eq_one)
rule = Theoria.Rewrite.Rule.new(:zero_to_one, zero_eq_one, proof: Theoria.Term.const(:zero_eq_one))

motive = Theoria.Term.lam(:n, nat, Theoria.Term.shift(nat, 1))
eq_rec = Theoria.Term.eq_rec(nat, motive, Theoria.Term.app(Theoria.Term.const(:succ), zero), Theoria.Term.refl(zero))
{:ok, eq_rec_step} = Theoria.Rewrite.once_with_step(eq_rec, rule)
eq_rec_step = Theoria.Rewrite.Proof.attach(env, eq_rec_step)

let_term = Theoria.Term.let(:x, nat, zero, Theoria.Term.bvar(0))
{:ok, let_step} = Theoria.Rewrite.once_with_step(let_term, rule)
let_step = Theoria.Rewrite.Proof.attach(env, let_step)

IO.puts("proof-producing rewrite trace")
IO.puts("  EqRec path: #{inspect(eq_rec_step.path)}")
IO.puts("  EqRec status: #{eq_rec_step.proof_result.status}")
IO.puts("  EqRec capability: #{eq_rec_step.proof_result.capability.reason}")
IO.puts("  EqRec inner capability: #{eq_rec_step.proof_result.capability.inner.reason}")
IO.puts("  let path: #{inspect(let_step.path)}")
IO.puts("  let status: #{let_step.proof_result.status}")
IO.puts("  let capability: #{let_step.proof_result.capability.reason}")

chain =
  nat
  |> Theoria.Equality.Chain.new(zero)
  |> Theoria.Equality.Chain.step(zero, Theoria.Term.refl(zero))
  |> Theoria.Equality.Chain.step(zero)
  |> Theoria.Equality.Chain.step(zero, Theoria.Term.refl(zero))

{:ok, realized} = Theoria.Equality.Chain.realize(env, chain, Theoria.Equation.Identity.simp(:example, :trace))

IO.puts("  chain strategy: #{realized.proof_strategy}")
