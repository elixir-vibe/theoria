# Trusted boundary

Theoria keeps the trusted boundary small. Automation may search, compile, plan, or render proof data, but the result matters only after the native kernel checks it. The Reach architecture policy enforces this directionally by forbidding the kernel layer from depending on DSL, library, rewrite/simp, Lean, or Mix task layers. Trusted-adjacent declaration admission helpers such as `Theoria.Kernel.ConstantAdmission`, `Theoria.Kernel.DefinitionAdmission`, `Theoria.Kernel.MatcherAdmission`, `Theoria.Kernel.TheoremAdmission`, and `Theoria.Kernel.InductiveAdmission` keep metadata-specific admission checks outside the main type-checking module while still treating successful admission as part of the native trusted path.

## Trusted

- `Theoria.Kernel` type checking and definitional equality.
- Environment replay through `Theoria.Kernel.validate_env/1` and reference replay assurance.
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

Rewrite and simp can transform terms, but search is not a proof. Proof-producing rewrite currently supports top-level rewrites, nested application function/argument congruence, and selected equality-side lifting when the constructed proof kernel-checks. Binder body/domain paths remain explicit boundaries unless the final proof is accepted by the kernel. Step proof data is reported as a structured proof result with status, capability, and optional proof term. Prefer APIs that return checked artifacts when the result must be trusted:

```elixir
{:ok, artifact} = Theoria.Simp.realize(env, term)
:ok = Theoria.Kernel.check(env, artifact.proof, artifact.type)
```

For declaration installation, provide an explicit public theorem name:

```elixir
{:ok, env, theorem} = Theoria.Simp.add_theorem(env, :my_simp_theorem, term)
```

Generated equation identities describe proof sources and traces; user-facing theorem declaration names are explicit choices.
