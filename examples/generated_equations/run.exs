alias Theoria.Equation.Eqns
alias Theoria.Equation.Identity
alias Theoria.Prelude

{:ok, env} = Prelude.env()
{:ok, equations} = Eqns.get(env, :nat_add)
IO.inspect(equations, label: "nat_add equations")

{:ok, artifact} = Eqns.realize(env, Identity.equation(:nat_add, :succ))
IO.puts("realized #{inspect(artifact.identity)}")
