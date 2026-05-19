# Trusted boundary

Theoria keeps the trusted boundary small. Automation may search, compile, plan, or render proof data, but the result matters only after the native kernel checks it.

## Trusted

- `Theoria.Kernel` type checking and definitional equality.
- Environment replay through `Theoria.Kernel.validate_env/1`.
- `%Theoria.Equation.Realized{}` artifacts produced by a successful kernel check.
- Installed theorem declarations admitted through `Theoria.Theorem.add_to_env/2` / kernel APIs.

## Untrusted helpers

- Equation compilation and matcher planning.
- Rewrite and simp search strategies.
- Mix task output and CLI formatting.
- Native validation corpus builders.
- Lean oracle encoding and external Lean execution.

The Lean oracle is contributor-only validation. It is not a runtime dependency and is not trusted by Theoria.

## Rewrite and simp

Rewrite and simp can transform terms, but search is not a proof. Proof-producing rewrite currently supports top-level rewrites and direct application function/argument congruence; unsupported paths are reported on step metadata. Prefer APIs that return checked artifacts when the result must be trusted:

```elixir
{:ok, artifact} = Theoria.Simp.realize(env, term)
:ok = Theoria.Kernel.check(env, artifact.proof, artifact.type)
```

For declaration installation, provide an explicit public theorem name:

```elixir
{:ok, env, theorem} = Theoria.Simp.add_theorem(env, :my_simp_theorem, term)
```

Generated equation identities describe proof sources and traces; user-facing theorem declaration names are explicit choices.
