alias Theoria.Equation
alias Theoria.Equation.Eqns
alias Theoria.Equation.Identity
alias Theoria.Prelude

{:ok, env} = Prelude.env()
{:ok, equations} = Eqns.get(env, :nat_add)
IO.inspect(equations, label: "nat_add equations")

{:ok, identities} = Equation.identities(env, :nat_add)
{:ok, unfold} = Equation.unfold_identity(env, :nat_add)
IO.inspect(identities, label: "nat_add identities")
IO.puts("nat_add unfold: #{Identity.format(unfold)}")
IO.puts("all generated identities: #{length(Equation.all_identities(env))}")

{:ok, artifact} = Eqns.realize(env, Identity.equation(:nat_add, :succ))
IO.puts("realized #{inspect(artifact.identity)}")

{:ok, theorems} = Equation.realize_all(env)
IO.puts("realized #{length(theorems)} generated theorem(s)")
