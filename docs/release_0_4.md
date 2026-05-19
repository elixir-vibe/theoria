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

## CLI artifact checks

The equation and simp Mix tasks expose checked artifact paths:

```bash
mix theoria.equations --realize nat_add
mix theoria.equations --realize --json nat_add
mix theoria.simp --examples --prove
mix theoria.simp --list
mix theoria.simp nat_add_zero --prove
mix theoria.simp nat_add_zero --prove --json
```

These commands do not make rewrite/simp search trusted. They surface the kernel-checked artifact produced after untrusted planning.

## Theorem installation remains explicit

Use a user-provided declaration name when installing a simplification result:

```elixir
Theoria.Simp.add_theorem(env, :my_simp_theorem, term)
```

Generated equation identities remain proof sources and trace identities; public theorem names are explicit user choices.

## Proof-backed rewrite databases

Generated equation databases can realize their source artifacts while constructing rules:

```elixir
Theoria.Rewrite.Database.from_env_equations(env, realize: true)
Theoria.Rewrite.Database.from_env_all_equations(env, realize: true)
```

The resulting `%Theoria.Rewrite.Rule{}` values carry the checked proof and `%Theoria.Equation.Realized{}` source artifact when realization succeeds. Rewrite search itself remains untrusted; these fields are proof inputs for checked downstream artifacts.

## Rewrite-step paths

Rewrite can now return structural step metadata with the rewritten path:

```elixir
Theoria.Rewrite.once_with_step(term, rule)
Theoria.Rewrite.Database.once_with_step(database, term)
```

Paths such as `[:arg]` or `[:fun, :arg]` are the groundwork for congruence lifting of local equation proofs into whole-term proofs. Rewrite steps also record schematic substitutions so proof-backed equation rules can instantiate their realized theorem proof at the matched arguments.

## Congruence and equality chain groundwork

`Theoria.Rewrite.Proof` can instantiate proof-backed rules at matched substitutions and lift supported `[:arg]` and `[:fun]` rewrites through application congruence. `Theoria.Equality.Chain` now consumes step proofs with equality transitivity where available, falling back to kernel-checked reflexivity only when the whole trace is definitionally equal.

Proof diagnostics are explicit on rewrite/simp steps:

- `:checked`
- `:not_requested`
- `:missing_rule_proof`
- `:unsupported_path`
- `:kernel_rejected`

Supported proof-producing paths currently cover top-level rewrites and direct application `[:arg]` / `[:fun]` rewrites. Deeper recursive congruence paths and binder-aware paths remain future work.

Generated equation rewrite databases support both eager and lazy source realization:

```elixir
Theoria.Rewrite.Database.from_env_equations(env, realize: true)
Theoria.Rewrite.Database.from_env_equations(env, realize: :lazy)
```

## Equality chain groundwork

`Theoria.Equality.Chain` records the shape needed for multi-step equality traces. The current implementation realizes chains by checking definitional equality with `refl`; future work can replace that with explicit transitivity/congruence proof terms without changing the simp result boundary.

## Kernel assurance groundwork

0.4 starts an Elixir-first kernel assurance track:

```bash
mix theoria.kernel.check
mix theoria.kernel.check --json
```

The check compares the production kernel with `Theoria.Kernel.Reference`, a slower explicit checker for the core term fragment (`Sort`, `Const`, `App`, `Lam`, `Forall`, `BVar`, `Let`, `Eq`, `Refl`, `EqRec`). Definitional equality now ignores diagnostic binder names for de Bruijn alpha-equivalent terms, universe `max` expressions are canonicalized for commutativity/associativity-sensitive level equality, and symbolic universe upper-bound shortcuts have been removed. It also compares production normalization/definitional equality with `Theoria.Kernel.Reference.Normalize`, a separate slow reference normalizer with reference primitive recursor reductions, compares expected rejection cases, checks curated Bool/Nat/List/Vec examples, and rechecks built-in theorem modules plus generated equation artifacts through the reference path. Property tests generate closed Bool, Nat, List Bool, and Vec Bool terms, equalities, and List eliminator applications for production/reference agreement. The Reach architecture policy now also guards the trusted boundary by forbidding kernel dependencies on DSL, library, rewrite/simp, Lean, or Mix task layers. The maintained source remains Elixir; Lean remains generated external oracle output, not a hand-written source of truth.

## Stability

This line is still experimental. Rewrite/simp search is untrusted; only the final proof artifact or installed theorem matters after kernel checking.
