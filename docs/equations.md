# Equation metadata and generated lemmas

Theoria's equation compiler is still internal groundwork, but compiled library definitions already carry auditable equation metadata.

Current flow:

```text
Signature + Case.Template + Clause/Pattern
  → Theoria.Equation.Schema.Builder
  → Theoria.Equation.Compiler
  → Theoria.Equation.Compiled
  → Theoria.Equation.Definition.Spec package
  → Theoria.Equation.Recursor.Descriptor package
  → Theoria.Equation.Matcher.Descriptor package
  → Theoria.Equation.Matcher.Type.Shape plan
  → Theoria.Equation.Matcher.Type package
  → Theoria.Equation.Matcher.Spec package
  → Theoria.Equation.Info metadata in the environment
  → generated Theoria.Equation.Lemma metadata
  → generated Theoria.Equation.Matcher.Equation metadata
  → Theoria.Env.Matcher declarations
  → Theoria.Equation.Extension registry helpers
  → Theoria.Equation.Eqns / Matcher.Eqns lookup
  → optional/lazy theorem realization
  → optional opaque theorem declarations
  → rewrite rules/databases
```

The metadata is Theoria-owned data. It is checked by native validation and can be translated to Lean by the contributor-only oracle, but Lean is not part of the runtime trusted path.


## Trusted boundary

Equation, matcher, rewrite, simp, and Lean-oracle machinery are intentionally outside the trusted kernel. They may synthesize terms, metadata, declarations, or external validation modules, but they do not make proofs trusted by themselves.

Trusted:

- `Theoria.Kernel` type-checks definitions, theorem declarations, inductive declarations, recursor metadata, and checked matcher declarations.
- Environment replay validates that stored declarations can be reconstructed through kernel entrypoints.

Untrusted helpers:

- `Theoria.Equation.Compiler`, `Schema.Builder`, `Matcher.Descriptor`, `Matcher.Type`, and `Matcher.Spec`;
- `Theoria.Equation.Eqns`, `Matcher.Eqns`, and `Extension.Registry` lookup/realization helpers;
- `Theoria.Rewrite` and `Theoria.Simp`;
- `Theoria.Lean.*` encoding and the external Lean oracle.

The safety rule is simple: generated artifacts become meaningful only after the native kernel checks them. The Lean oracle is contributor confidence, not runtime trust.

## Stored equation metadata

Compiled definitions such as `bool_not`, `nat_add`, `list_length`, and `list_append` store `Theoria.Equation.Info` in their environment declaration metadata. Use:

```elixir
Theoria.Equation.Info.fetch(env, :nat_add)
Theoria.Equation.Info.all(env)
Theoria.Equation.Info.equation?(env, :nat_add)
```

`Theoria.Equation.Signature` summarizes the function telescope, recursive argument, result type, and fixed parameters. Fixed parameters are derived from the signature's parameter telescope by default, with explicit overrides still available for future edge cases. `Theoria.Equation.Case.Template` describes schematic constructor equations without tying schema generation to concrete library definition names. `Theoria.Equation.Schema.Builder` turns those inputs into validated schemas and matcher metadata, including discriminant names/positions/types and simple overlap records. The compiler returns `Theoria.Equation.Compiled`, which contains the recursor body plus generated clause/schema/matcher metadata. `Theoria.Equation.Definition.Spec` wraps that compiler result with the final checked definition type/value before installation. `Theoria.Equation.Recursor.Descriptor` reads checked `Env.Recursor` / `Env.RecursorRule` metadata, including indexed rule patterns, constructor fields, and recursive field indices. `Theoria.Equation.Matcher.Descriptor` can represent indexed Vec-like matcher shapes with normalized matcher-owned fields, but matcher type/body generation currently consumes descriptors fully only for the supported non-indexed families. `Theoria.Equation.Matcher.Descriptor` combines that recursor-derived shape with schema/matcher metadata into a structural matcher description with discriminants, alternatives, result, and recursor. `Theoria.Equation.Matcher.Type` first plans a descriptor-derived `Matcher.Type.Shape` containing parameters, motive, discriminants, alternatives, alternative case binders, result, recursor arguments, recursor metadata when available, and body, then generates checked matcher type/body packages by folding that telescope for supported simple shapes. Alternative case binders and recursor arguments are derived from planned binders and normalized descriptor fields for the current simple families; indexed descriptors are planned into validated shapes with major motive arguments/results, per-constructor case results, recursor metadata-backed arity/count checks, and a recursor application body. Experimental indexed emitters can fold those shapes into terms for inspection only; checked matcher declaration emission remains disabled until dependent matcher generation exists. `Theoria.Equation.Matcher.Spec` installs those packages as `Theoria.Env.Matcher` metadata. Stored metadata records the definition name, checked type/value, recursive argument position, fixed parameters, level parameters, original clause metadata, Lean-shaped matcher alternatives, matcher discriminants, matcher declaration names, matcher mode, and a validated schema that drives schematic theorem generation.

## Generated equation lemmas

For the currently supported library definitions, Theoria can generate schematic equation-lemma metadata from compiler-owned `Equation.Schema` entries:

```elixir
{:ok, info} = Theoria.Equation.Info.fetch(env, :nat_add)
Theoria.Equation.Lemma.generated_for(info)
#=> [nat_add.eq_zero, nat_add.eq_succ]
```

Supported definitions today:

- `bool_not`
- `bool_and`
- `bool_or`
- `nat_add`
- `list_length`
- `list_append`

These generated lemmas are metadata until explicitly checked or installed. Schematic lemmas carry binders and an equality type, so they can be checked as forall-theorems by reflexivity when the two sides are definitionally equal, and optionally installed as opaque theorem declarations:

```elixir
Theoria.Equation.Lemma.add_generated_to_env(env, :nat_add)
```

The prelude does not install generated equation theorems by default yet.

## Equation lookup

`Theoria.Equation.Eqns` is the small Theoria equivalent of Lean's equation-theorem lookup layer:

```elixir
Theoria.Equation.Eqns.get(env, :nat_add)
#=> {:ok, [:"nat_add.eq_zero", :"nat_add.eq_succ"]}

Theoria.Equation.Eqns.generated(env, :nat_add)
Theoria.Equation.Eqns.unfold(env, :nat_add)
Theoria.Equation.Eqns.source(env, :"nat_add.eq_succ")
Theoria.Equation.Eqns.installed?(env, :nat_add)
```

`Theoria.Equation.Matcher.Eqns` is the matcher-equation side of the same groundwork and reads first-class matcher declarations from the environment:

```elixir
Theoria.Equation.Matcher.Eqns.get(env, :"nat_add.match_1")
#=> {:ok, [:"nat_add.match_1.eq_zero", :"nat_add.match_1.eq_succ"]}

Theoria.Equation.Matcher.Eqns.source(env, :"nat_add.match_1.eq_succ")
#=> {:ok, :"nat_add.match_1"}
```

Generated theorem metadata can also be realized without installing declarations:

```elixir
Theoria.Equation.Eqns.realize(env, :nat_add)
Theoria.Equation.Eqns.realize(env, :"nat_add.eq_succ")
Theoria.Equation.Eqns.realize(env, :"nat_add.eq_def")
Theoria.Equation.Matcher.Eqns.realize(env, :"nat_add.match_1.eq_succ")
```

`Theoria.Equation.Extension` provides typed registry helpers for source lookup, matcher lookup, unfold names, generated theorem-name enumeration, and an in-memory `Extension.Registry` snapshot. It is currently rebuilt from environment metadata rather than stored as a persistent disk-backed extension.

## Matcher maturity

Matcher declarations have explicit modes:

- `:source_aligned` — the declaration is kernel checked, but its type/value mirror the source definition while the matcher metadata is developed.
- `:matcher` — the declaration has a generated matcher type and body.

Current status:

- indexed Vec-like matcher descriptors can be represented, validated, and planned into `Matcher.Type.Shape` from `vec_ind`, including constructor fields, recursive fields, index binders, dependent motive binders/results, per-alternative index patterns, constructor applications, per-constructor case results, recursor arguments, and a planned recursor application body. Experimental indexed type/value term emission exists for inspection, but normal `Matcher.Type`/`Matcher.Spec` checked declaration emission intentionally rejects indexed shapes until dependent matcher generation exists;
- unary Bool definitions such as `bool_not` use `:matcher` mode with type `∀ motive, ∀ b, motive → motive → motive` and a Bool recursor body;
- Nat definitions such as `nat_add` use `:matcher` mode with type `∀ motive, ∀ n, motive → (Nat → motive → motive) → motive` and a Nat recursor body;
- List definitions such as `list_length` and `list_append` use `:matcher` mode with a List recursor body;
- binary Bool definitions such as `bool_and` and `bool_or` use `:matcher` mode with two discriminants and four alternatives.

Future stages will add true matcher arity for more families, independently compiled matcher bodies, and persistent matcher equation extensions.

## Rewrite databases

Generated equation lemmas can feed the provisional rewrite database:

```elixir
database = Theoria.Rewrite.Database.from_env_equations(env)
Theoria.Rewrite.Database.once(database, term)
```

The rewrite layer is intentionally untrusted and first-order for now. It can match schematic equation-rule binders, but it does not produce proofs and does not replace kernel checking.

## Simp groundwork

`Theoria.Simp` is a tiny consumer of generated equation databases:

```elixir
Theoria.Simp.once(env, term)
Theoria.Simp.normalize(env, term, max_steps: 100)
```

It repeatedly applies priority-sorted generated equation rewrite rules and returns the final term plus rich `%Theoria.Simp.Step{}` trace entries. It is not a trusted simplifier yet.

A small smoke-test task runs built-in examples:

```bash
mix theoria.simp --examples
```

## Mix tooling

List equation metadata, generated lemma names, matcher metadata, discriminants, alternatives, unfold metadata, and matcher equations:

```bash
mix theoria.equations
mix theoria.equations nat_add
```

Opt-in install generated equation theorems during the task run:

```bash
mix theoria.equations --install nat_add
```

Native validation kernel-checks generated equation theorems, matcher declarations, registry coherence, and lazy realization APIs, then reports them explicitly:

```text
✓ matcher declarations: 6 checked matcher(s)
✓ generated equations: 16 theorem(s)
✓ matcher equations: 16 theorem(s)
```

It can also show equation metadata:

```bash
mix theoria.validate --equations
mix theoria.validate --equations --verbose
```

The verbose form prints generated lemma names under each stored equation definition.

## Limitations by layer

| Layer | Current limitation |
| --- | --- |
| Public syntax | No public equation-definition syntax yet. Library definitions feed the internal compiler directly. |
| Fixed parameters | Signature-derived fixed parameters only; no mutual-recursive permutation/dependency analysis yet. |
| Recursor.Descriptor | Describes non-indexed and indexed recursor rules, including Vec index patterns, constructor fields, and recursive field indices; it is not yet a full dependent telescope analyzer. |
| Matcher.Descriptor | Recursor-informed Bool/Nat/List descriptors plus indexed Vec-like descriptor shape with normalized matcher-owned fields; dependent/indexed matcher type/body generation is still unsupported. |
| Matcher.Type | Plans and validates descriptor-derived `Matcher.Type.Shape` values with parameters, indices, motive binders/results, discriminants, alternatives, derived case binders, index patterns, constructor applications, per-constructor case results, recursor metadata-backed counts, recursor arguments, and recursor application bodies, then folds simple non-indexed telescopes. Experimental indexed emitters are term-planning only; not a general dependent matcher compiler. |
| Eqns / Matcher.Eqns | Generated theorem metadata and realization helpers, not a persistent Lean-style environment extension. |
| Extension.Registry | In-memory snapshot rebuilt from environment metadata; not persisted to disk. |
| Structural recursion | No general structural recursion checker and no `brecOn`/below dictionaries. |
| Rewrite / Simp | Untrusted first-order rewriting with no proof terms and no attribute/prioritized simp database. |
| Lean oracle | Contributor-only external validation; not a runtime dependency and not trusted by the kernel. |

The current generator is deliberately small. It emits schematic equation lemmas from schemas for the built-in Bool/Nat/List definitions, derives fixed parameters from signatures, and stores basic matcher/discriminant/overlap metadata in checked matcher declarations. It is not yet Lean's full equation theorem machinery.
