# 0.4 development boundary

The 0.4 development line turns simplification from a term-rewriting helper into proof-producing automation groundwork.

## Proof-producing simp

`Theoria.Simp.normalize/3` accepts `prove: true` and attaches a kernel-checked equality artifact to the result when the simplification trace is definitionally justified:

```elixir
{:ok, env} = Theoria.Prelude.env()
term = Theoria.Term.const(:nat_add) |> Theoria.Term.app(Theoria.Term.const(:zero)) |> Theoria.Term.app(Theoria.Term.const(:zero))

result = Theoria.Simp.normalize(env, term, prove: true)
result.realized
```

The artifact is a `%Theoria.Equation.Realized{}` with an identity such as `Theoria.Equation.Identity.simp()`. It is checked by the native kernel and remains separate from theorem installation.

## Theorem installation remains explicit

Use a user-provided declaration name when installing a simplification result:

```elixir
Theoria.Simp.add_theorem(env, :my_simp_theorem, term)
```

Generated equation identities remain proof sources and trace identities; public theorem names are explicit user choices.

## Equality chain groundwork

`Theoria.Equality.Chain` records the shape needed for multi-step equality traces. The current implementation realizes chains by checking definitional equality with `refl`; future work can replace that with explicit transitivity/congruence proof terms without changing the simp result boundary.

## Stability

This line is still experimental. Rewrite/simp search is untrusted; only the final proof artifact or installed theorem matters after kernel checking.
